-- =====================================================
-- Dispute Resolution System
-- =====================================================

-- Dispute types
CREATE TYPE dispute_type AS ENUM (
    'item_not_received',
    'item_not_as_described',
    'damaged_item',
    'counterfeit_item',
    'unauthorized_transaction',
    'seller_not_responding',
    'buyer_not_responding',
    'payment_issue',
    'other'
);

-- Dispute status
CREATE TYPE dispute_status AS ENUM (
    'open',
    'awaiting_seller_response',
    'awaiting_buyer_response',
    'under_review',
    'escalated',
    'resolved',
    'closed',
    'cancelled'
);

-- Resolution types
CREATE TYPE resolution_type AS ENUM (
    'full_refund',
    'partial_refund',
    'replacement',
    'return_and_refund',
    'keep_item_partial_refund',
    'no_action',
    'cancelled_by_buyer',
    'cancelled_by_seller'
);

-- Disputes table
CREATE TABLE disputes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    dispute_number VARCHAR(20) UNIQUE NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    
    -- Parties involved
    initiated_by UUID REFERENCES profiles(id) NOT NULL,
    respondent_id UUID REFERENCES profiles(id) NOT NULL,
    
    -- Dispute details
    type dispute_type NOT NULL,
    status dispute_status DEFAULT 'open',
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    
    -- Claimed amounts
    claimed_amount DECIMAL(10,2),
    approved_amount DECIMAL(10,2),
    
    -- Evidence
    buyer_evidence JSONB DEFAULT '[]', -- Array of {type, url, description}
    seller_evidence JSONB DEFAULT '[]',
    
    -- Response deadline
    response_deadline TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '3 days'),
    
    -- Resolution
    resolution_type resolution_type,
    resolution_notes TEXT,
    resolved_by UUID REFERENCES profiles(id),
    resolved_at TIMESTAMPTZ,
    
    -- Escalation
    escalated_to_support BOOLEAN DEFAULT FALSE,
    escalated_at TIMESTAMPTZ,
    escalation_reason TEXT,
    support_agent_id UUID REFERENCES profiles(id),
    support_ticket_id VARCHAR(100),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    
    -- Auto-close after 30 days of inactivity
    auto_close_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'
);

-- Dispute messages
CREATE TABLE dispute_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    dispute_id UUID REFERENCES disputes(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES profiles(id) NOT NULL,
    
    -- Message content
    message TEXT NOT NULL,
    attachments JSONB DEFAULT '[]', -- Array of {type, url, name, size}
    
    -- Message type
    is_system_message BOOLEAN DEFAULT FALSE,
    is_staff_message BOOLEAN DEFAULT FALSE,
    is_private_note BOOLEAN DEFAULT FALSE, -- Only visible to staff
    
    -- Read status
    read_by_buyer BOOLEAN DEFAULT FALSE,
    read_by_seller BOOLEAN DEFAULT FALSE,
    read_by_staff BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dispute evidence
CREATE TABLE dispute_evidence (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    dispute_id UUID REFERENCES disputes(id) ON DELETE CASCADE NOT NULL,
    submitted_by UUID REFERENCES profiles(id) NOT NULL,
    
    -- Evidence details
    evidence_type VARCHAR(50) NOT NULL, -- 'photo', 'video', 'document', 'screenshot', 'receipt'
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES profiles(id),
    verified_at TIMESTAMPTZ,
    verification_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dispute history/timeline
CREATE TABLE dispute_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    dispute_id UUID REFERENCES disputes(id) ON DELETE CASCADE NOT NULL,
    
    -- Event details
    event_type VARCHAR(50) NOT NULL, -- 'created', 'responded', 'escalated', 'resolved', etc.
    description TEXT NOT NULL,
    
    -- Actor
    actor_id UUID REFERENCES profiles(id),
    actor_type VARCHAR(20), -- 'buyer', 'seller', 'system', 'support'
    
    -- Changes
    old_status dispute_status,
    new_status dispute_status,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dispute templates for common issues
CREATE TABLE dispute_templates (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type dispute_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description_template TEXT NOT NULL,
    
    -- Suggested evidence
    required_evidence JSONB DEFAULT '[]', -- Array of evidence types needed
    
    -- Resolution guidelines
    resolution_guidelines TEXT,
    typical_resolution resolution_type,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sequence for dispute numbers
CREATE SEQUENCE dispute_number_seq START 1000;

-- Enable RLS
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_templates ENABLE ROW LEVEL SECURITY;

-- Dispute policies
CREATE POLICY "Users can view their disputes" ON disputes
    FOR SELECT USING (
        auth.uid() IN (initiated_by, respondent_id)
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND metadata->>'is_support_agent' = 'true'
        )
    );

CREATE POLICY "Users can create disputes for their orders" ON disputes
    FOR INSERT WITH CHECK (
        auth.uid() = initiated_by
        AND EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = disputes.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

CREATE POLICY "Parties can update their disputes" ON disputes
    FOR UPDATE USING (
        auth.uid() IN (initiated_by, respondent_id)
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND metadata->>'is_support_agent' = 'true'
        )
    );

-- Message policies
CREATE POLICY "Parties can view dispute messages" ON dispute_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM disputes
            WHERE disputes.id = dispute_messages.dispute_id
            AND (
                auth.uid() IN (disputes.initiated_by, disputes.respondent_id)
                OR (is_private_note = FALSE AND EXISTS (
                    SELECT 1 FROM profiles
                    WHERE id = auth.uid()
                    AND metadata->>'is_support_agent' = 'true'
                ))
            )
        )
    );

CREATE POLICY "Parties can send messages" ON dispute_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM disputes
            WHERE disputes.id = dispute_messages.dispute_id
            AND auth.uid() IN (disputes.initiated_by, disputes.respondent_id)
            AND disputes.status NOT IN ('closed', 'cancelled')
        )
    );

-- Evidence policies
CREATE POLICY "Parties can view evidence" ON dispute_evidence
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM disputes
            WHERE disputes.id = dispute_evidence.dispute_id
            AND auth.uid() IN (disputes.initiated_by, disputes.respondent_id)
        )
    );

CREATE POLICY "Parties can submit evidence" ON dispute_evidence
    FOR INSERT WITH CHECK (
        auth.uid() = submitted_by
        AND EXISTS (
            SELECT 1 FROM disputes
            WHERE disputes.id = dispute_evidence.dispute_id
            AND auth.uid() IN (disputes.initiated_by, disputes.respondent_id)
            AND disputes.status NOT IN ('closed', 'cancelled', 'resolved')
        )
    );

-- History policies (read-only for parties)
CREATE POLICY "Parties can view dispute history" ON dispute_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM disputes
            WHERE disputes.id = dispute_history.dispute_id
            AND auth.uid() IN (disputes.initiated_by, disputes.respondent_id)
        )
    );

-- Template policies (public read)
CREATE POLICY "Templates are public" ON dispute_templates
    FOR SELECT USING (is_active = TRUE);

-- Indexes
CREATE INDEX idx_disputes_order ON disputes(order_id);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_parties ON disputes(initiated_by, respondent_id);
CREATE INDEX idx_disputes_created ON disputes(created_at DESC);
CREATE INDEX idx_dispute_messages_dispute ON dispute_messages(dispute_id, created_at);
CREATE INDEX idx_dispute_evidence_dispute ON dispute_evidence(dispute_id);
CREATE INDEX idx_dispute_history_dispute ON dispute_history(dispute_id, created_at DESC);

-- Function to generate dispute number
CREATE OR REPLACE FUNCTION generate_dispute_number()
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'DSP-' || LPAD(nextval('dispute_number_seq')::text, 8, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to create dispute
CREATE OR REPLACE FUNCTION create_dispute(
    p_order_id UUID,
    p_type dispute_type,
    p_title VARCHAR,
    p_description TEXT,
    p_claimed_amount DECIMAL DEFAULT NULL,
    p_evidence JSONB DEFAULT '[]'
)
RETURNS UUID AS $$
DECLARE
    v_dispute_id UUID;
    v_dispute_number VARCHAR;
    v_order RECORD;
    v_respondent_id UUID;
BEGIN
    -- Get order details
    SELECT * INTO v_order
    FROM orders o
    WHERE o.id = p_order_id
    AND auth.uid() IN (o.buyer_id, o.seller_id);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found or access denied';
    END IF;
    
    -- Check if dispute already exists
    IF EXISTS (
        SELECT 1 FROM disputes
        WHERE order_id = p_order_id
        AND status NOT IN ('closed', 'cancelled')
    ) THEN
        RAISE EXCEPTION 'An active dispute already exists for this order';
    END IF;
    
    -- Determine respondent
    IF auth.uid() = v_order.buyer_id THEN
        v_respondent_id := v_order.seller_id;
    ELSE
        v_respondent_id := v_order.buyer_id;
    END IF;
    
    -- Generate dispute number
    v_dispute_number := generate_dispute_number();
    
    -- Create dispute
    INSERT INTO disputes (
        dispute_number,
        order_id,
        initiated_by,
        respondent_id,
        type,
        title,
        description,
        claimed_amount,
        status
    ) VALUES (
        v_dispute_number,
        p_order_id,
        auth.uid(),
        v_respondent_id,
        p_type,
        p_title,
        p_description,
        p_claimed_amount,
        'awaiting_' || CASE 
            WHEN auth.uid() = v_order.buyer_id THEN 'seller' 
            ELSE 'buyer' 
        END || '_response'
    ) RETURNING id INTO v_dispute_id;
    
    -- Add evidence if provided
    IF auth.uid() = v_order.buyer_id THEN
        UPDATE disputes
        SET buyer_evidence = p_evidence
        WHERE id = v_dispute_id;
    ELSE
        UPDATE disputes
        SET seller_evidence = p_evidence
        WHERE id = v_dispute_id;
    END IF;
    
    -- Create initial message
    INSERT INTO dispute_messages (
        dispute_id,
        sender_id,
        message,
        is_system_message
    ) VALUES (
        v_dispute_id,
        auth.uid(),
        'Dispute created: ' || p_description,
        FALSE
    );
    
    -- Add to history
    INSERT INTO dispute_history (
        dispute_id,
        event_type,
        description,
        actor_id,
        actor_type,
        new_status
    ) VALUES (
        v_dispute_id,
        'created',
        'Dispute created by ' || CASE 
            WHEN auth.uid() = v_order.buyer_id THEN 'buyer' 
            ELSE 'seller' 
        END,
        auth.uid(),
        CASE 
            WHEN auth.uid() = v_order.buyer_id THEN 'buyer' 
            ELSE 'seller' 
        END,
        'open'
    );
    
    -- Update order status
    UPDATE orders
    SET metadata = metadata || jsonb_build_object('has_dispute', true, 'dispute_id', v_dispute_id)
    WHERE id = p_order_id;
    
    -- Notify respondent
    PERFORM create_notification(
        v_respondent_id,
        'dispute_opened',
        'Dispute Opened',
        'A dispute has been opened for order #' || v_order.order_number,
        '/disputes/' || v_dispute_id,
        related_order_id := p_order_id
    );
    
    RETURN v_dispute_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to respond to dispute
CREATE OR REPLACE FUNCTION respond_to_dispute(
    p_dispute_id UUID,
    p_message TEXT,
    p_evidence JSONB DEFAULT '[]'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_dispute RECORD;
BEGIN
    -- Get dispute details
    SELECT * INTO v_dispute
    FROM disputes
    WHERE id = p_dispute_id
    AND auth.uid() = respondent_id
    AND status IN ('awaiting_seller_response', 'awaiting_buyer_response')
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Dispute not found or response not allowed';
    END IF;
    
    -- Update evidence
    IF auth.uid() = (
        SELECT buyer_id FROM orders WHERE id = v_dispute.order_id
    ) THEN
        UPDATE disputes
        SET buyer_evidence = buyer_evidence || p_evidence
        WHERE id = p_dispute_id;
    ELSE
        UPDATE disputes
        SET seller_evidence = seller_evidence || p_evidence
        WHERE id = p_dispute_id;
    END IF;
    
    -- Add message
    INSERT INTO dispute_messages (
        dispute_id,
        sender_id,
        message
    ) VALUES (
        p_dispute_id,
        auth.uid(),
        p_message
    );
    
    -- Update status
    UPDATE disputes
    SET status = 'under_review',
        updated_at = NOW()
    WHERE id = p_dispute_id;
    
    -- Add to history
    INSERT INTO dispute_history (
        dispute_id,
        event_type,
        description,
        actor_id,
        old_status,
        new_status
    ) VALUES (
        p_dispute_id,
        'responded',
        'Response submitted',
        auth.uid(),
        v_dispute.status,
        'under_review'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to escalate dispute
CREATE OR REPLACE FUNCTION escalate_dispute(
    p_dispute_id UUID,
    p_reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_dispute RECORD;
BEGIN
    -- Get dispute
    SELECT * INTO v_dispute
    FROM disputes
    WHERE id = p_dispute_id
    AND auth.uid() IN (initiated_by, respondent_id)
    AND status NOT IN ('escalated', 'resolved', 'closed')
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Dispute not found or escalation not allowed';
    END IF;
    
    -- Update dispute
    UPDATE disputes
    SET status = 'escalated',
        escalated_to_support = TRUE,
        escalated_at = NOW(),
        escalation_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_dispute_id;
    
    -- Add system message
    INSERT INTO dispute_messages (
        dispute_id,
        sender_id,
        message,
        is_system_message
    ) VALUES (
        p_dispute_id,
        auth.uid(),
        'Dispute escalated to support team. Reason: ' || p_reason,
        TRUE
    );
    
    -- Add to history
    INSERT INTO dispute_history (
        dispute_id,
        event_type,
        description,
        actor_id,
        old_status,
        new_status
    ) VALUES (
        p_dispute_id,
        'escalated',
        'Escalated to support: ' || p_reason,
        auth.uid(),
        v_dispute.status,
        'escalated'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert default dispute templates
INSERT INTO dispute_templates (type, title, description_template, required_evidence, typical_resolution) VALUES
    ('item_not_received', 
     'Item Not Received', 
     'I have not received my order despite it showing as delivered.',
     '["shipping_tracking", "delivery_photo", "communication_screenshots"]',
     'full_refund'),
    
    ('item_not_as_described',
     'Item Not As Described',
     'The item I received does not match the description or photos in the listing.',
     '["item_photos", "listing_screenshot", "description_comparison"]',
     'partial_refund'),
    
    ('damaged_item',
     'Damaged Item',
     'The item arrived damaged or broken.',
     '["damage_photos", "packaging_photos", "unboxing_video"]',
     'return_and_refund'),
    
    ('counterfeit_item',
     'Counterfeit Item',
     'The item appears to be counterfeit or fake.',
     '["authenticity_comparison", "item_photos", "expert_opinion"]',
     'full_refund')
ON CONFLICT DO NOTHING;

-- Function to auto-close inactive disputes
CREATE OR REPLACE FUNCTION auto_close_inactive_disputes()
RETURNS void AS $$
BEGIN
    UPDATE disputes
    SET status = 'closed',
        closed_at = NOW(),
        resolution_type = 'no_action',
        resolution_notes = 'Automatically closed due to inactivity'
    WHERE status IN ('open', 'awaiting_seller_response', 'awaiting_buyer_response')
    AND updated_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;