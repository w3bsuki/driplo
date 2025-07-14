-- =====================================================
-- Returns & Refunds System
-- =====================================================

-- Return reasons enum
CREATE TYPE return_reason AS ENUM (
    'defective',
    'not_as_described',
    'wrong_item',
    'doesnt_fit',
    'changed_mind',
    'damaged_in_shipping',
    'missing_parts',
    'quality_issue',
    'other'
);

-- Return status enum
CREATE TYPE return_status AS ENUM (
    'requested',
    'approved',
    'rejected',
    'shipped_back',
    'received',
    'inspecting',
    'refunded',
    'replaced',
    'closed'
);

-- Returns table
CREATE TABLE returns (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    return_number VARCHAR(20) UNIQUE NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    order_item_id UUID REFERENCES order_items(id) ON DELETE CASCADE NOT NULL,
    
    -- Return details
    status return_status DEFAULT 'requested' NOT NULL,
    reason return_reason NOT NULL,
    reason_details TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    
    -- Condition of returned item
    item_condition VARCHAR(50), -- 'unopened', 'like_new', 'used', 'damaged'
    
    -- Refund info
    refund_amount DECIMAL(10,2),
    refund_method VARCHAR(50), -- 'original_payment', 'store_credit', 'replacement'
    refund_status VARCHAR(50), -- 'pending', 'processing', 'completed', 'failed'
    refund_transaction_id UUID REFERENCES payment_refunds(id),
    store_credit_issued DECIMAL(10,2) DEFAULT 0,
    
    -- Return shipping
    return_shipping_paid_by VARCHAR(20), -- 'buyer', 'seller', 'platform'
    return_shipping_label_url TEXT,
    return_tracking_number VARCHAR(100),
    return_carrier shipping_carrier,
    return_shipping_cost DECIMAL(10,2),
    
    -- Timestamps
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    inspected_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    
    -- Users involved
    requested_by UUID REFERENCES profiles(id) NOT NULL,
    approved_by UUID REFERENCES profiles(id),
    inspected_by UUID REFERENCES profiles(id),
    
    -- Evidence and notes
    buyer_photos JSONB DEFAULT '[]', -- Array of photo URLs
    seller_photos JSONB DEFAULT '[]', -- Photos after inspection
    buyer_notes TEXT,
    seller_notes TEXT,
    admin_notes TEXT,
    
    -- Resolution
    resolution_notes TEXT,
    final_decision VARCHAR(50) -- 'full_refund', 'partial_refund', 'replacement', 'rejected'
);

-- Return messages for communication
CREATE TABLE return_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    return_id UUID REFERENCES returns(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES profiles(id) NOT NULL,
    message TEXT NOT NULL,
    attachments JSONB DEFAULT '[]',
    is_internal BOOLEAN DEFAULT FALSE, -- Internal notes not visible to users
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Store credit for users
CREATE TABLE store_credits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    original_amount DECIMAL(10,2) NOT NULL,
    
    -- Source
    source_type VARCHAR(50) NOT NULL, -- 'return', 'gift', 'compensation', 'promotion'
    source_id UUID, -- return_id or other reference
    
    -- Usage
    used_amount DECIMAL(10,2) DEFAULT 0 CHECK (used_amount >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Validity
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    
    -- Metadata
    notes TEXT,
    issued_by UUID REFERENCES profiles(id)
);

-- Store credit usage history
CREATE TABLE store_credit_usage (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    credit_id UUID REFERENCES store_credits(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    amount_used DECIMAL(10,2) NOT NULL CHECK (amount_used > 0),
    used_at TIMESTAMPTZ DEFAULT NOW()
);

-- Return sequence for return numbers
CREATE SEQUENCE return_number_seq START 1000;

-- Enable RLS
ALTER TABLE returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE return_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_credit_usage ENABLE ROW LEVEL SECURITY;

-- Return policies
CREATE POLICY "Users can view returns for their orders" ON returns
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = returns.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

CREATE POLICY "Buyers can create returns" ON returns
    FOR INSERT WITH CHECK (
        auth.uid() = requested_by AND
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = returns.order_id
            AND orders.buyer_id = auth.uid()
            AND orders.status IN ('delivered', 'completed')
        )
    );

CREATE POLICY "Sellers can update return status" ON returns
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = returns.order_id
            AND orders.seller_id = auth.uid()
        )
    );

-- Return message policies
CREATE POLICY "Users can view return messages" ON return_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM returns r
            JOIN orders o ON o.id = r.order_id
            WHERE r.id = return_messages.return_id
            AND auth.uid() IN (o.buyer_id, o.seller_id)
            AND (NOT is_internal OR auth.uid() = o.seller_id)
        )
    );

CREATE POLICY "Users can send return messages" ON return_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM returns r
            JOIN orders o ON o.id = r.order_id
            WHERE r.id = return_messages.return_id
            AND auth.uid() IN (o.buyer_id, o.seller_id)
        )
    );

-- Store credit policies
CREATE POLICY "Users can view their store credits" ON store_credits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their credit usage" ON store_credit_usage
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM store_credits
            WHERE store_credits.id = store_credit_usage.credit_id
            AND store_credits.user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_returns_order ON returns(order_id);
CREATE INDEX idx_returns_status ON returns(status);
CREATE INDEX idx_returns_requested_at ON returns(requested_at DESC);
CREATE INDEX idx_return_messages_return ON return_messages(return_id);
CREATE INDEX idx_store_credits_user ON store_credits(user_id);
CREATE INDEX idx_store_credits_active ON store_credits(user_id, is_active) WHERE is_active = TRUE;
CREATE INDEX idx_store_credit_usage_credit ON store_credit_usage(credit_id);

-- Function to generate return number
CREATE OR REPLACE FUNCTION generate_return_number()
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'RET-' || LPAD(nextval('return_number_seq')::text, 8, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to create return request
CREATE OR REPLACE FUNCTION create_return_request(
    p_order_id UUID,
    p_order_item_id UUID,
    p_reason return_reason,
    p_reason_details TEXT,
    p_quantity INTEGER DEFAULT 1,
    p_photos JSONB DEFAULT '[]'
)
RETURNS UUID AS $$
DECLARE
    v_return_id UUID;
    v_return_number VARCHAR;
    v_order RECORD;
    v_item RECORD;
BEGIN
    -- Validate order
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
    AND buyer_id = auth.uid()
    AND status IN ('delivered', 'completed');
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not eligible for return';
    END IF;
    
    -- Validate order item
    SELECT * INTO v_item
    FROM order_items
    WHERE id = p_order_item_id
    AND order_id = p_order_id
    AND is_returned = FALSE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order item not found or already returned';
    END IF;
    
    -- Check return window (30 days)
    IF v_order.delivered_at < NOW() - INTERVAL '30 days' THEN
        RAISE EXCEPTION 'Return window has expired';
    END IF;
    
    -- Generate return number
    v_return_number := generate_return_number();
    
    -- Create return
    INSERT INTO returns (
        return_number,
        order_id,
        order_item_id,
        reason,
        reason_details,
        quantity,
        requested_by,
        buyer_photos,
        refund_amount
    ) VALUES (
        v_return_number,
        p_order_id,
        p_order_item_id,
        p_reason,
        p_reason_details,
        p_quantity,
        auth.uid(),
        p_photos,
        v_item.total_price
    ) RETURNING id INTO v_return_id;
    
    -- Create initial message
    INSERT INTO return_messages (
        return_id,
        sender_id,
        message
    ) VALUES (
        v_return_id,
        auth.uid(),
        'Return requested for: ' || p_reason_details
    );
    
    -- Notify seller
    PERFORM create_notification(
        v_order.seller_id,
        'return_requested',
        'Return Request',
        'A return has been requested for order #' || v_order.order_number,
        '/returns/' || v_return_id,
        related_order_id := p_order_id
    );
    
    RETURN v_return_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to approve return
CREATE OR REPLACE FUNCTION approve_return(
    p_return_id UUID,
    p_return_shipping_label TEXT DEFAULT NULL,
    p_seller_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_return RECORD;
    v_order RECORD;
BEGIN
    -- Get return details
    SELECT r.*, o.seller_id, o.buyer_id, o.order_number
    INTO v_return
    FROM returns r
    JOIN orders o ON o.id = r.order_id
    WHERE r.id = p_return_id
    AND o.seller_id = auth.uid()
    AND r.status = 'requested';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Return not found or not authorized';
    END IF;
    
    -- Update return status
    UPDATE returns
    SET status = 'approved',
        approved_at = NOW(),
        approved_by = auth.uid(),
        return_shipping_label_url = p_return_shipping_label,
        seller_notes = p_seller_notes
    WHERE id = p_return_id;
    
    -- Add message
    INSERT INTO return_messages (
        return_id,
        sender_id,
        message
    ) VALUES (
        p_return_id,
        auth.uid(),
        'Return approved. ' || COALESCE(p_seller_notes, 'Please ship the item back using the provided label.')
    );
    
    -- Notify buyer
    PERFORM create_notification(
        v_return.buyer_id,
        'return_approved',
        'Return Approved',
        'Your return request for order #' || v_return.order_number || ' has been approved',
        '/returns/' || p_return_id
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to process refund
CREATE OR REPLACE FUNCTION process_return_refund(
    p_return_id UUID,
    p_refund_amount DECIMAL,
    p_refund_method VARCHAR DEFAULT 'original_payment'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_return RECORD;
    v_refund_id UUID;
BEGIN
    -- Get return details
    SELECT r.*, o.id as order_id, pt.id as transaction_id
    INTO v_return
    FROM returns r
    JOIN orders o ON o.id = r.order_id
    LEFT JOIN payment_transactions pt ON pt.order_id = o.id AND pt.status = 'succeeded'
    WHERE r.id = p_return_id
    AND r.status IN ('received', 'inspecting')
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Return not eligible for refund';
    END IF;
    
    -- Create refund based on method
    IF p_refund_method = 'store_credit' THEN
        -- Issue store credit
        INSERT INTO store_credits (
            user_id,
            amount,
            original_amount,
            source_type,
            source_id,
            notes,
            issued_by
        ) VALUES (
            v_return.requested_by,
            p_refund_amount,
            p_refund_amount,
            'return',
            p_return_id,
            'Store credit for return #' || v_return.return_number,
            auth.uid()
        );
        
        UPDATE returns
        SET store_credit_issued = p_refund_amount;
        
    ELSE
        -- Process payment refund
        IF v_return.transaction_id IS NOT NULL THEN
            INSERT INTO payment_refunds (
                transaction_id,
                order_id,
                amount,
                reason,
                notes,
                initiated_by
            ) VALUES (
                v_return.transaction_id,
                v_return.order_id,
                p_refund_amount,
                'return',
                'Refund for return #' || v_return.return_number,
                auth.uid()
            ) RETURNING id INTO v_refund_id;
            
            UPDATE returns
            SET refund_transaction_id = v_refund_id;
        END IF;
    END IF;
    
    -- Update return status
    UPDATE returns
    SET status = 'refunded',
        refund_amount = p_refund_amount,
        refund_method = p_refund_method,
        refund_status = 'completed',
        refunded_at = NOW(),
        closed_at = NOW()
    WHERE id = p_return_id;
    
    -- Update order item
    UPDATE order_items
    SET is_returned = TRUE,
        returned_at = NOW()
    WHERE id = v_return.order_item_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate available store credit
CREATE OR REPLACE FUNCTION get_available_store_credit(p_user_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    RETURN COALESCE(
        SUM(amount - used_amount),
        0
    )
    FROM store_credits
    WHERE user_id = p_user_id
    AND is_active = TRUE
    AND (expires_at IS NULL OR expires_at > NOW());
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to apply store credit to order
CREATE OR REPLACE FUNCTION apply_store_credit_to_order(
    p_order_id UUID,
    p_amount DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
    v_available DECIMAL;
    v_applied DECIMAL := 0;
    v_remaining DECIMAL := p_amount;
    credit RECORD;
BEGIN
    -- Get available credit
    v_available := get_available_store_credit(auth.uid());
    
    IF v_available < p_amount THEN
        RAISE EXCEPTION 'Insufficient store credit';
    END IF;
    
    -- Apply credits FIFO
    FOR credit IN
        SELECT * FROM store_credits
        WHERE user_id = auth.uid()
        AND is_active = TRUE
        AND amount > used_amount
        AND (expires_at IS NULL OR expires_at > NOW())
        ORDER BY issued_at
    LOOP
        DECLARE
            v_credit_available DECIMAL;
            v_to_use DECIMAL;
        BEGIN
            v_credit_available := credit.amount - credit.used_amount;
            v_to_use := LEAST(v_credit_available, v_remaining);
            
            -- Update credit usage
            UPDATE store_credits
            SET used_amount = used_amount + v_to_use
            WHERE id = credit.id;
            
            -- Record usage
            INSERT INTO store_credit_usage (
                credit_id,
                order_id,
                amount_used
            ) VALUES (
                credit.id,
                p_order_id,
                v_to_use
            );
            
            v_applied := v_applied + v_to_use;
            v_remaining := v_remaining - v_to_use;
            
            EXIT WHEN v_remaining <= 0;
        END;
    END LOOP;
    
    -- Update order discount
    UPDATE orders
    SET discount_amount = discount_amount + v_applied,
        total_amount = total_amount - v_applied
    WHERE id = p_order_id;
    
    RETURN v_applied;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;