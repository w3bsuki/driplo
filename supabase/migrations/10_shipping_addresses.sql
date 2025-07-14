-- =====================================================
-- Shipping Addresses Management
-- =====================================================

-- User shipping addresses
CREATE TABLE shipping_addresses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    address_label VARCHAR(50), -- 'Home', 'Work', etc.
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country_code VARCHAR(2) NOT NULL DEFAULT 'US',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE shipping_addresses ENABLE ROW LEVEL SECURITY;

-- Shipping address policies
CREATE POLICY "Users can view their own addresses" ON shipping_addresses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own addresses" ON shipping_addresses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses" ON shipping_addresses
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses" ON shipping_addresses
    FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_shipping_addresses_user ON shipping_addresses(user_id);
CREATE INDEX idx_shipping_addresses_default ON shipping_addresses(user_id, is_default) WHERE is_default = TRUE;

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        -- Remove default from other addresses
        UPDATE shipping_addresses
        SET is_default = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id
        AND is_default = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to maintain single default address
CREATE TRIGGER maintain_single_default_address
    BEFORE INSERT OR UPDATE OF is_default ON shipping_addresses
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION ensure_single_default_address();

-- Function to set first address as default
CREATE OR REPLACE FUNCTION set_first_address_default()
RETURNS TRIGGER AS $$
DECLARE
    address_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO address_count
    FROM shipping_addresses
    WHERE user_id = NEW.user_id;
    
    -- If this is the first address, make it default
    IF address_count = 1 THEN
        NEW.is_default := TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set first address as default
CREATE TRIGGER first_address_default
    BEFORE INSERT ON shipping_addresses
    FOR EACH ROW
    EXECUTE FUNCTION set_first_address_default();

-- Function to validate address
CREATE OR REPLACE FUNCTION validate_shipping_address()
RETURNS TRIGGER AS $$
BEGIN
    -- Basic validation
    IF LENGTH(NEW.postal_code) < 3 THEN
        RAISE EXCEPTION 'Invalid postal code';
    END IF;
    
    IF LENGTH(NEW.phone) < 10 THEN
        RAISE EXCEPTION 'Invalid phone number';
    END IF;
    
    -- Normalize country code to uppercase
    NEW.country_code := UPPER(NEW.country_code);
    
    -- Update timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for address validation
CREATE TRIGGER validate_address_trigger
    BEFORE INSERT OR UPDATE ON shipping_addresses
    FOR EACH ROW
    EXECUTE FUNCTION validate_shipping_address();

-- Add billing address support to profiles
ALTER TABLE profiles ADD COLUMN default_billing_address_id UUID REFERENCES shipping_addresses(id);

-- Function to format address for display
CREATE OR REPLACE FUNCTION format_shipping_address(address_id UUID)
RETURNS TEXT AS $$
DECLARE
    addr RECORD;
    formatted TEXT;
BEGIN
    SELECT * INTO addr
    FROM shipping_addresses
    WHERE id = address_id;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    formatted := addr.full_name || E'\n' ||
                 addr.address_line1 || E'\n';
    
    IF addr.address_line2 IS NOT NULL THEN
        formatted := formatted || addr.address_line2 || E'\n';
    END IF;
    
    formatted := formatted || 
                 addr.city || ', ' || addr.state_province || ' ' || addr.postal_code || E'\n' ||
                 addr.country_code;
    
    RETURN formatted;
END;
$$ LANGUAGE plpgsql STABLE;