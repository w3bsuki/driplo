-- =====================================================
-- Shopping Cart System
-- =====================================================

-- Shopping cart for users
CREATE TABLE shopping_carts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    
    UNIQUE(user_id)
);

-- Cart items
CREATE TABLE cart_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cart_id UUID REFERENCES shopping_carts(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    added_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(cart_id, listing_id)
);

-- Enable RLS
ALTER TABLE shopping_carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Cart policies
CREATE POLICY "Users can view their own cart" ON shopping_carts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own cart" ON shopping_carts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cart" ON shopping_carts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cart" ON shopping_carts
    FOR DELETE USING (auth.uid() = user_id);

-- Cart items policies
CREATE POLICY "Users can view their cart items" ON cart_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shopping_carts
            WHERE shopping_carts.id = cart_items.cart_id
            AND shopping_carts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add items to their cart" ON cart_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM shopping_carts
            WHERE shopping_carts.id = cart_items.cart_id
            AND shopping_carts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their cart items" ON cart_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM shopping_carts
            WHERE shopping_carts.id = cart_items.cart_id
            AND shopping_carts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can remove items from their cart" ON cart_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM shopping_carts
            WHERE shopping_carts.id = cart_items.cart_id
            AND shopping_carts.user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_carts_user ON shopping_carts(user_id);
CREATE INDEX idx_carts_expires ON shopping_carts(expires_at);
CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_cart_items_listing ON cart_items(listing_id);

-- Function to get or create cart
CREATE OR REPLACE FUNCTION get_or_create_cart(user_uuid UUID)
RETURNS UUID AS $$
DECLARE
    cart_uuid UUID;
BEGIN
    -- Try to get existing cart
    SELECT id INTO cart_uuid
    FROM shopping_carts
    WHERE user_id = user_uuid
    AND expires_at > NOW();
    
    -- Create new cart if none exists
    IF cart_uuid IS NULL THEN
        INSERT INTO shopping_carts (user_id)
        VALUES (user_uuid)
        RETURNING id INTO cart_uuid;
    END IF;
    
    RETURN cart_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean expired carts
CREATE OR REPLACE FUNCTION clean_expired_carts()
RETURNS void AS $$
BEGIN
    DELETE FROM shopping_carts
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;