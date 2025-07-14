-- =====================================================
-- Complete Order Management System
-- =====================================================

-- Order statuses enum
CREATE TYPE order_status AS ENUM (
    'pending_payment',
    'payment_processing',
    'payment_failed',
    'paid',
    'preparing',
    'shipped',
    'in_transit',
    'delivered',
    'completed',
    'cancelled',
    'refunded'
);

-- Create sequence for order numbers
CREATE SEQUENCE order_number_seq START 1000;

-- Orders table
CREATE TABLE orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Order details
    status order_status DEFAULT 'pending_payment' NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    shipping_cost DECIMAL(10,2) DEFAULT 0 CHECK (shipping_cost >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Shipping info
    shipping_address_id UUID REFERENCES shipping_addresses(id),
    shipping_address_snapshot JSONB NOT NULL, -- Store address at time of order
    
    -- Payment info
    payment_method VARCHAR(50), -- 'card', 'paypal', 'bank_transfer'
    payment_status VARCHAR(50) DEFAULT 'pending',
    payment_intent_id VARCHAR(255), -- Stripe/PayPal reference
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    paid_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    
    -- Additional info
    buyer_note TEXT,
    seller_note TEXT,
    cancellation_reason TEXT,
    metadata JSONB DEFAULT '{}',
    
    -- Ensure buyer and seller are different
    CHECK (buyer_id != seller_id)
);

-- Order items
CREATE TABLE order_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE SET NULL,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    
    -- Product snapshot at time of order
    product_snapshot JSONB NOT NULL, -- Store product details
    
    -- Item details
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    
    -- Status
    is_returned BOOLEAN DEFAULT FALSE,
    returned_at TIMESTAMPTZ,
    return_reason TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order status history
CREATE TABLE order_status_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    old_status order_status,
    new_status order_status NOT NULL,
    changed_by UUID REFERENCES profiles(id),
    reason TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- Order policies
CREATE POLICY "Users can view their orders" ON orders
    FOR SELECT USING (auth.uid() IN (buyer_id, seller_id));

CREATE POLICY "Buyers can create orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Sellers can update order status" ON orders
    FOR UPDATE USING (auth.uid() = seller_id)
    WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Buyers can cancel pending orders" ON orders
    FOR UPDATE USING (
        auth.uid() = buyer_id 
        AND status IN ('pending_payment', 'payment_processing')
    );

-- Order items policies
CREATE POLICY "Users can view order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

CREATE POLICY "Order items created with orders" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
            AND auth.uid() = orders.buyer_id
        )
    );

-- Status history policies
CREATE POLICY "Users can view order status history" ON order_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

-- Indexes
CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_seller ON orders(seller_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_listing ON order_items(listing_id);
CREATE INDEX idx_order_status_history_order ON order_status_history(order_id, created_at DESC);

-- Function to generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'ORD-' || LPAD(nextval('order_number_seq')::text, 8, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to calculate order totals
CREATE OR REPLACE FUNCTION calculate_order_total(
    p_subtotal DECIMAL,
    p_shipping DECIMAL,
    p_tax DECIMAL,
    p_discount DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
    RETURN p_subtotal + p_shipping + p_tax - p_discount;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update order timestamps
CREATE OR REPLACE FUNCTION update_order_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    
    -- Update specific timestamps based on status changes
    IF OLD.status != NEW.status THEN
        CASE NEW.status
            WHEN 'paid' THEN
                NEW.paid_at := NOW();
            WHEN 'shipped' THEN
                NEW.shipped_at := NOW();
            WHEN 'delivered' THEN
                NEW.delivered_at := NOW();
            WHEN 'completed' THEN
                NEW.completed_at := NOW();
            WHEN 'cancelled' THEN
                NEW.cancelled_at := NOW();
            ELSE
                -- Do nothing
        END CASE;
        
        -- Log status change
        INSERT INTO order_status_history (
            order_id,
            old_status,
            new_status,
            changed_by
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            auth.uid()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for order timestamps
CREATE TRIGGER order_timestamp_trigger
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_order_timestamps();

-- Function to create order from cart
CREATE OR REPLACE FUNCTION create_order_from_cart(
    p_cart_id UUID,
    p_shipping_address_id UUID,
    p_shipping_cost DECIMAL DEFAULT 0,
    p_buyer_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_order_id UUID;
    v_buyer_id UUID;
    v_seller_id UUID;
    v_subtotal DECIMAL := 0;
    v_order_number VARCHAR;
    v_address RECORD;
    cart_item RECORD;
BEGIN
    -- Get buyer from cart
    SELECT user_id INTO v_buyer_id
    FROM shopping_carts
    WHERE id = p_cart_id;
    
    IF v_buyer_id IS NULL THEN
        RAISE EXCEPTION 'Cart not found';
    END IF;
    
    -- Get shipping address
    SELECT * INTO v_address
    FROM shipping_addresses
    WHERE id = p_shipping_address_id
    AND user_id = v_buyer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid shipping address';
    END IF;
    
    -- For now, create separate orders for each seller
    -- In a real implementation, you might group by seller
    FOR cart_item IN
        SELECT ci.*, l.seller_id, l.price, l.title, l.images
        FROM cart_items ci
        JOIN listings l ON l.id = ci.listing_id
        WHERE ci.cart_id = p_cart_id
    LOOP
        v_seller_id := cart_item.seller_id;
        v_subtotal := cart_item.quantity * cart_item.price;
        v_order_number := generate_order_number();
        
        -- Create order
        INSERT INTO orders (
            order_number,
            buyer_id,
            seller_id,
            subtotal,
            shipping_cost,
            total_amount,
            shipping_address_id,
            shipping_address_snapshot,
            buyer_note
        ) VALUES (
            v_order_number,
            v_buyer_id,
            v_seller_id,
            v_subtotal,
            p_shipping_cost,
            v_subtotal + p_shipping_cost,
            p_shipping_address_id,
            row_to_json(v_address),
            p_buyer_note
        ) RETURNING id INTO v_order_id;
        
        -- Create order item
        INSERT INTO order_items (
            order_id,
            listing_id,
            variant_id,
            product_snapshot,
            quantity,
            unit_price,
            total_price
        ) VALUES (
            v_order_id,
            cart_item.listing_id,
            cart_item.variant_id,
            jsonb_build_object(
                'title', cart_item.title,
                'price', cart_item.price,
                'images', cart_item.images
            ),
            cart_item.quantity,
            cart_item.price,
            v_subtotal
        );
    END LOOP;
    
    -- Clear cart after order creation
    DELETE FROM cart_items WHERE cart_id = p_cart_id;
    
    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update seller stats on order completion
CREATE OR REPLACE FUNCTION update_seller_stats_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Update total sales and earnings
        UPDATE profiles
        SET total_sales = total_sales + 1,
            total_earnings = total_earnings + NEW.total_amount
        WHERE id = NEW.seller_id;
        
        -- Update buyer purchases
        UPDATE profiles
        SET total_purchases = total_purchases + 1
        WHERE id = NEW.buyer_id;
        
        -- Update listing sold status if all stock sold
        UPDATE listings l
        SET status = 'sold'
        FROM order_items oi
        WHERE oi.order_id = NEW.id
        AND l.id = oi.listing_id
        AND NOT EXISTS (
            SELECT 1 FROM product_variants pv
            WHERE pv.listing_id = l.id
            AND pv.stock_quantity > 0
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for seller stats
CREATE TRIGGER update_seller_stats_trigger
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_seller_stats_on_order();