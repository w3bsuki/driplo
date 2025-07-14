-- =====================================================
-- Product Variants and Inventory System
-- =====================================================

-- Product variants (sizes, colors, etc.)
CREATE TABLE product_variants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    sku VARCHAR(100),
    variant_type VARCHAR(50) NOT NULL, -- 'size', 'color', 'style', etc.
    variant_value VARCHAR(100) NOT NULL, -- 'XL', 'Red', etc.
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(listing_id, variant_type, variant_value)
);

-- Inventory tracking logs
CREATE TABLE inventory_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE,
    change_quantity INTEGER NOT NULL, -- positive for additions, negative for reductions
    reason VARCHAR(100) NOT NULL, -- 'sale', 'return', 'adjustment', 'initial_stock'
    reference_id UUID, -- order_id or return_id
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

-- Add variant support to cart items
ALTER TABLE cart_items ADD COLUMN variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE;
-- Update unique constraint to include variant
ALTER TABLE cart_items DROP CONSTRAINT cart_items_cart_id_listing_id_key;
ALTER TABLE cart_items ADD CONSTRAINT cart_items_unique UNIQUE(cart_id, listing_id, variant_id);

-- Enable RLS
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_logs ENABLE ROW LEVEL SECURITY;

-- Product variants policies
CREATE POLICY "Variants are viewable by everyone" ON product_variants
    FOR SELECT USING (true);

CREATE POLICY "Sellers can manage their variants" ON product_variants
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = product_variants.listing_id
            AND listings.seller_id = auth.uid()
        )
    );

-- Inventory logs policies
CREATE POLICY "Sellers can view their inventory logs" ON inventory_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = inventory_logs.listing_id
            AND listings.seller_id = auth.uid()
        )
    );

CREATE POLICY "Sellers can create inventory logs" ON inventory_logs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = inventory_logs.listing_id
            AND listings.seller_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_variants_listing ON product_variants(listing_id);
CREATE INDEX idx_variants_available ON product_variants(is_available) WHERE is_available = TRUE;
CREATE INDEX idx_variants_stock ON product_variants(stock_quantity) WHERE stock_quantity > 0;
CREATE INDEX idx_inventory_logs_variant ON inventory_logs(variant_id);
CREATE INDEX idx_inventory_logs_listing ON inventory_logs(listing_id);
CREATE INDEX idx_inventory_logs_created ON inventory_logs(created_at DESC);

-- Function to check variant availability
CREATE OR REPLACE FUNCTION check_variant_availability(
    p_variant_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    available_stock INTEGER;
BEGIN
    SELECT stock_quantity INTO available_stock
    FROM product_variants
    WHERE id = p_variant_id
    AND is_available = TRUE;
    
    RETURN COALESCE(available_stock, 0) >= p_quantity;
END;
$$ LANGUAGE plpgsql;

-- Function to update variant stock
CREATE OR REPLACE FUNCTION update_variant_stock(
    p_variant_id UUID,
    p_change_quantity INTEGER,
    p_reason VARCHAR,
    p_reference_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    new_stock INTEGER;
    listing_uuid UUID;
BEGIN
    -- Get listing_id
    SELECT listing_id INTO listing_uuid
    FROM product_variants
    WHERE id = p_variant_id;
    
    -- Update stock
    UPDATE product_variants
    SET stock_quantity = stock_quantity + p_change_quantity
    WHERE id = p_variant_id
    RETURNING stock_quantity INTO new_stock;
    
    -- Log the change
    INSERT INTO inventory_logs (
        variant_id,
        listing_id,
        change_quantity,
        reason,
        reference_id,
        created_by
    ) VALUES (
        p_variant_id,
        listing_uuid,
        p_change_quantity,
        p_reason,
        p_reference_id,
        p_user_id
    );
    
    -- Update availability if stock is 0
    IF new_stock <= 0 THEN
        UPDATE product_variants
        SET is_available = FALSE
        WHERE id = p_variant_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add variant support to listings
ALTER TABLE listings ADD COLUMN has_variants BOOLEAN DEFAULT FALSE;
ALTER TABLE listings ADD COLUMN total_stock INTEGER DEFAULT 0;

-- Function to update listing stock from variants
CREATE OR REPLACE FUNCTION update_listing_total_stock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE listings
    SET total_stock = (
        SELECT COALESCE(SUM(stock_quantity), 0)
        FROM product_variants
        WHERE listing_id = COALESCE(NEW.listing_id, OLD.listing_id)
    ),
    has_variants = TRUE
    WHERE id = COALESCE(NEW.listing_id, OLD.listing_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update listing stock
CREATE TRIGGER update_listing_stock_trigger
    AFTER INSERT OR UPDATE OR DELETE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION update_listing_total_stock();