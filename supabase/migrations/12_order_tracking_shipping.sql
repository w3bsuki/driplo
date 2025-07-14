-- =====================================================
-- Order Tracking and Shipping System
-- =====================================================

-- Shipping carriers enum
CREATE TYPE shipping_carrier AS ENUM ('ups', 'fedex', 'usps', 'dhl', 'local', 'other');

-- Tracking status enum
CREATE TYPE tracking_status AS ENUM (
    'label_created',
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
    'delivery_failed',
    'returned_to_sender'
);

-- Order tracking information
CREATE TABLE order_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    carrier shipping_carrier NOT NULL,
    tracking_number VARCHAR(100) NOT NULL,
    tracking_url TEXT,
    status tracking_status DEFAULT 'label_created',
    
    -- Shipping details
    ship_date DATE,
    estimated_delivery DATE,
    actual_delivery TIMESTAMPTZ,
    
    -- Package info
    package_weight DECIMAL(10,2),
    package_dimensions JSONB, -- {length, width, height, unit}
    
    -- Tracking updates
    last_update TIMESTAMPTZ DEFAULT NOW(),
    last_location VARCHAR(255),
    tracking_events JSONB DEFAULT '[]', -- Array of tracking events
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    
    UNIQUE(order_id, tracking_number)
);

-- Shipping labels storage
CREATE TABLE shipping_labels (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    tracking_id UUID REFERENCES order_tracking(id) ON DELETE CASCADE,
    
    -- Label info
    label_url TEXT NOT NULL,
    label_format VARCHAR(10) DEFAULT 'PDF', -- PDF, PNG, ZPL
    cost DECIMAL(10,2),
    
    -- Service details
    service_type VARCHAR(50), -- 'ground', 'express', '2-day', 'overnight'
    insurance_amount DECIMAL(10,2),
    signature_required BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_labels ENABLE ROW LEVEL SECURITY;

-- Tracking policies
CREATE POLICY "Users can view tracking for their orders" ON order_tracking
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_tracking.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

CREATE POLICY "Sellers can create tracking" ON order_tracking
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_tracking.order_id
            AND orders.seller_id = auth.uid()
        )
    );

CREATE POLICY "Sellers can update tracking" ON order_tracking
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_tracking.order_id
            AND orders.seller_id = auth.uid()
        )
    );

-- Shipping label policies
CREATE POLICY "Users can view labels for their orders" ON shipping_labels
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = shipping_labels.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

CREATE POLICY "Sellers can create labels" ON shipping_labels
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = shipping_labels.order_id
            AND orders.seller_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_tracking_order ON order_tracking(order_id);
CREATE INDEX idx_tracking_number ON order_tracking(tracking_number);
CREATE INDEX idx_tracking_status ON order_tracking(status);
CREATE INDEX idx_tracking_delivery ON order_tracking(estimated_delivery) WHERE status != 'delivered';
CREATE INDEX idx_labels_order ON shipping_labels(order_id);

-- Function to add tracking event
CREATE OR REPLACE FUNCTION add_tracking_event(
    p_tracking_id UUID,
    p_status tracking_status,
    p_location VARCHAR(255),
    p_description TEXT,
    p_timestamp TIMESTAMPTZ DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update tracking status and events
    UPDATE order_tracking
    SET status = p_status,
        last_update = p_timestamp,
        last_location = p_location,
        tracking_events = tracking_events || jsonb_build_object(
            'timestamp', p_timestamp,
            'status', p_status,
            'location', p_location,
            'description', p_description
        )
    WHERE id = p_tracking_id;
    
    -- Update order status based on tracking
    IF p_status = 'delivered' THEN
        UPDATE orders o
        SET status = 'delivered',
            delivered_at = p_timestamp
        FROM order_tracking ot
        WHERE ot.id = p_tracking_id
        AND o.id = ot.order_id
        AND o.status = 'shipped';
        
        -- Update actual delivery date
        UPDATE order_tracking
        SET actual_delivery = p_timestamp
        WHERE id = p_tracking_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create shipping label
CREATE OR REPLACE FUNCTION create_shipping_label(
    p_order_id UUID,
    p_carrier shipping_carrier,
    p_tracking_number VARCHAR(100),
    p_service_type VARCHAR(50),
    p_label_url TEXT,
    p_cost DECIMAL DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
    v_tracking_id UUID;
    v_label_id UUID;
BEGIN
    -- Create or update tracking record
    INSERT INTO order_tracking (
        order_id,
        carrier,
        tracking_number,
        created_by
    ) VALUES (
        p_order_id,
        p_carrier,
        p_tracking_number,
        auth.uid()
    )
    ON CONFLICT (order_id, tracking_number) 
    DO UPDATE SET 
        carrier = EXCLUDED.carrier,
        last_update = NOW()
    RETURNING id INTO v_tracking_id;
    
    -- Create shipping label
    INSERT INTO shipping_labels (
        order_id,
        tracking_id,
        label_url,
        service_type,
        cost
    ) VALUES (
        p_order_id,
        v_tracking_id,
        p_label_url,
        p_service_type,
        p_cost
    ) RETURNING id INTO v_label_id;
    
    -- Update order status to shipped
    UPDATE orders
    SET status = 'shipped',
        shipped_at = NOW()
    WHERE id = p_order_id
    AND status IN ('paid', 'preparing');
    
    RETURN v_label_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate shipping cost
CREATE OR REPLACE FUNCTION calculate_shipping_cost(
    p_weight DECIMAL,
    p_from_zip VARCHAR(10),
    p_to_zip VARCHAR(10),
    p_service_type VARCHAR(50)
)
RETURNS DECIMAL AS $$
DECLARE
    base_cost DECIMAL;
    distance_multiplier DECIMAL := 1.0;
BEGIN
    -- Basic shipping cost calculation
    -- In production, this would integrate with shipping APIs
    
    -- Base cost by service type
    CASE p_service_type
        WHEN 'ground' THEN base_cost := 5.99;
        WHEN 'express' THEN base_cost := 12.99;
        WHEN '2-day' THEN base_cost := 19.99;
        WHEN 'overnight' THEN base_cost := 29.99;
        ELSE base_cost := 7.99;
    END CASE;
    
    -- Add weight-based cost (per pound)
    base_cost := base_cost + (p_weight * 0.50);
    
    -- Simple distance calculation (would use real API)
    IF SUBSTRING(p_from_zip, 1, 3) != SUBSTRING(p_to_zip, 1, 3) THEN
        distance_multiplier := 1.5;
    END IF;
    
    RETURN ROUND(base_cost * distance_multiplier, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get tracking URL
CREATE OR REPLACE FUNCTION get_tracking_url(
    p_carrier shipping_carrier,
    p_tracking_number VARCHAR(100)
)
RETURNS TEXT AS $$
BEGIN
    CASE p_carrier
        WHEN 'ups' THEN 
            RETURN 'https://www.ups.com/track?tracknum=' || p_tracking_number;
        WHEN 'fedex' THEN 
            RETURN 'https://www.fedex.com/fedextrack/?tracknumbers=' || p_tracking_number;
        WHEN 'usps' THEN 
            RETURN 'https://tools.usps.com/go/TrackConfirmAction?tLabels=' || p_tracking_number;
        WHEN 'dhl' THEN 
            RETURN 'https://www.dhl.com/en/express/tracking.html?AWB=' || p_tracking_number;
        ELSE 
            RETURN NULL;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update tracking URL when tracking number is added
CREATE OR REPLACE FUNCTION update_tracking_url()
RETURNS TRIGGER AS $$
BEGIN
    NEW.tracking_url := get_tracking_url(NEW.carrier, NEW.tracking_number);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate tracking URL
CREATE TRIGGER generate_tracking_url
    BEFORE INSERT OR UPDATE OF tracking_number, carrier ON order_tracking
    FOR EACH ROW
    EXECUTE FUNCTION update_tracking_url();