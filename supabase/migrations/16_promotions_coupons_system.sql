-- =====================================================
-- Promotions & Coupons System
-- =====================================================

-- Discount types
CREATE TYPE discount_type AS ENUM ('percentage', 'fixed_amount', 'free_shipping', 'buy_x_get_y');

-- Promotion target types
CREATE TYPE promotion_target AS ENUM ('all_items', 'category', 'seller', 'specific_items');

-- Coupons table
CREATE TABLE coupons (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Discount details
    discount_type discount_type NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
    minimum_purchase DECIMAL(10,2) DEFAULT 0,
    maximum_discount DECIMAL(10,2), -- Max discount for percentage type
    
    -- Buy X Get Y details
    buy_quantity INTEGER,
    get_quantity INTEGER,
    
    -- Usage limits
    usage_limit INTEGER, -- Total uses allowed
    usage_count INTEGER DEFAULT 0,
    usage_limit_per_user INTEGER DEFAULT 1,
    
    -- Validity period
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Target restrictions
    target_type promotion_target DEFAULT 'all_items',
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    category_ids UUID[] DEFAULT '{}',
    listing_ids UUID[] DEFAULT '{}',
    excluded_listing_ids UUID[] DEFAULT '{}',
    
    -- User restrictions
    new_users_only BOOLEAN DEFAULT FALSE,
    user_ids UUID[] DEFAULT '{}', -- Specific users who can use this
    minimum_account_age_days INTEGER,
    
    -- Stack-ability
    can_stack BOOLEAN DEFAULT FALSE,
    
    -- Analytics
    total_discount_given DECIMAL(12,2) DEFAULT 0,
    
    -- Metadata
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Coupon usage tracking
CREATE TABLE coupon_usage (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    coupon_id UUID REFERENCES coupons(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Usage details
    discount_amount DECIMAL(10,2) NOT NULL,
    order_amount DECIMAL(10,2),
    
    -- Status
    is_successful BOOLEAN DEFAULT TRUE,
    failure_reason TEXT,
    
    used_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate usage on same order
    UNIQUE(coupon_id, order_id)
);

-- Flash sales / time-limited promotions
CREATE TABLE flash_sales (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    banner_image_url TEXT,
    
    -- Timing
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Discount
    discount_type discount_type NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    
    -- Targets
    target_type promotion_target DEFAULT 'all_items',
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    category_ids UUID[] DEFAULT '{}',
    listing_ids UUID[] DEFAULT '{}',
    
    -- Limits
    stock_limit INTEGER, -- Total items that can be sold
    stock_sold INTEGER DEFAULT 0,
    max_per_user INTEGER DEFAULT 1,
    
    -- Featured placement
    is_featured BOOLEAN DEFAULT FALSE,
    featured_order INTEGER DEFAULT 0,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (ends_at > starts_at)
);

-- Bundle deals
CREATE TABLE bundle_deals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Bundle items
    listing_ids UUID[] NOT NULL CHECK (array_length(listing_ids, 1) >= 2),
    
    -- Pricing
    bundle_price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2) NOT NULL,
    savings_amount DECIMAL(10,2) GENERATED ALWAYS AS (original_price - bundle_price) STORED,
    savings_percentage DECIMAL(5,2) GENERATED ALWAYS AS ((original_price - bundle_price) / original_price * 100) STORED,
    
    -- Availability
    is_active BOOLEAN DEFAULT TRUE,
    stock_limit INTEGER,
    stock_sold INTEGER DEFAULT 0,
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Loyalty points system
CREATE TABLE loyalty_points (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Points balance
    total_earned INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0,
    current_balance INTEGER GENERATED ALWAYS AS (total_earned - total_spent) STORED,
    
    -- Tier info
    tier_name VARCHAR(50) DEFAULT 'Bronze',
    tier_level INTEGER DEFAULT 1,
    
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Points transactions
CREATE TABLE points_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Transaction details
    points INTEGER NOT NULL, -- Positive for earning, negative for spending
    transaction_type VARCHAR(50) NOT NULL, -- 'purchase', 'referral', 'review', 'redemption'
    description TEXT,
    
    -- References
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Balance after transaction
    balance_after INTEGER NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE flash_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE bundle_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;

-- Coupon policies
CREATE POLICY "Public coupons are viewable" ON coupons
    FOR SELECT USING (
        is_active = TRUE 
        AND (seller_id IS NULL OR seller_id = auth.uid())
        AND (user_ids = '{}' OR auth.uid() = ANY(user_ids))
    );

CREATE POLICY "Sellers can create coupons" ON coupons
    FOR INSERT WITH CHECK (
        created_by = auth.uid() 
        AND (seller_id IS NULL OR seller_id = auth.uid())
    );

CREATE POLICY "Sellers can update their coupons" ON coupons
    FOR UPDATE USING (created_by = auth.uid());

-- Coupon usage policies
CREATE POLICY "Users can view their usage" ON coupon_usage
    FOR SELECT USING (user_id = auth.uid());

-- Flash sale policies
CREATE POLICY "Active flash sales are public" ON flash_sales
    FOR SELECT USING (
        is_active = TRUE 
        AND starts_at <= NOW() 
        AND ends_at > NOW()
    );

CREATE POLICY "Sellers can create flash sales" ON flash_sales
    FOR INSERT WITH CHECK (
        created_by = auth.uid() 
        AND (seller_id IS NULL OR seller_id = auth.uid())
    );

-- Bundle deal policies
CREATE POLICY "Active bundles are viewable" ON bundle_deals
    FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Sellers can manage their bundles" ON bundle_deals
    FOR ALL USING (seller_id = auth.uid());

-- Loyalty points policies
CREATE POLICY "Users can view their points" ON loyalty_points
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view their point history" ON points_transactions
    FOR SELECT USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_coupons_code ON coupons(code) WHERE is_active = TRUE;
CREATE INDEX idx_coupons_valid ON coupons(valid_from, valid_until) WHERE is_active = TRUE;
CREATE INDEX idx_coupon_usage_user ON coupon_usage(user_id);
CREATE INDEX idx_coupon_usage_order ON coupon_usage(order_id);
CREATE INDEX idx_flash_sales_active ON flash_sales(starts_at, ends_at) WHERE is_active = TRUE;
CREATE INDEX idx_bundle_deals_seller ON bundle_deals(seller_id) WHERE is_active = TRUE;
CREATE INDEX idx_loyalty_points_user ON loyalty_points(user_id);
CREATE INDEX idx_points_transactions_user ON points_transactions(user_id, created_at DESC);

-- Function to validate coupon
CREATE OR REPLACE FUNCTION validate_coupon(
    p_code VARCHAR,
    p_user_id UUID,
    p_order_amount DECIMAL,
    p_listing_ids UUID[] DEFAULT '{}'
)
RETURNS TABLE (
    is_valid BOOLEAN,
    discount_amount DECIMAL,
    error_message TEXT,
    coupon_id UUID
) AS $$
DECLARE
    v_coupon RECORD;
    v_usage_count INTEGER;
    v_discount DECIMAL := 0;
    v_error TEXT;
BEGIN
    -- Get coupon details
    SELECT * INTO v_coupon
    FROM coupons
    WHERE UPPER(code) = UPPER(p_code)
    AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 'Invalid coupon code', NULL::UUID;
        RETURN;
    END IF;
    
    -- Check validity period
    IF NOW() < v_coupon.valid_from OR (v_coupon.valid_until IS NOT NULL AND NOW() > v_coupon.valid_until) THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 'Coupon has expired', v_coupon.id;
        RETURN;
    END IF;
    
    -- Check minimum purchase
    IF p_order_amount < v_coupon.minimum_purchase THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 
            'Minimum purchase of $' || v_coupon.minimum_purchase || ' required', 
            v_coupon.id;
        RETURN;
    END IF;
    
    -- Check usage limits
    IF v_coupon.usage_limit IS NOT NULL AND v_coupon.usage_count >= v_coupon.usage_limit THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 'Coupon usage limit reached', v_coupon.id;
        RETURN;
    END IF;
    
    -- Check per-user usage limit
    SELECT COUNT(*) INTO v_usage_count
    FROM coupon_usage
    WHERE coupon_id = v_coupon.id
    AND user_id = p_user_id
    AND is_successful = TRUE;
    
    IF v_usage_count >= v_coupon.usage_limit_per_user THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 'You have already used this coupon', v_coupon.id;
        RETURN;
    END IF;
    
    -- Check user restrictions
    IF v_coupon.user_ids != '{}' AND NOT (p_user_id = ANY(v_coupon.user_ids)) THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 'This coupon is not available for your account', v_coupon.id;
        RETURN;
    END IF;
    
    -- Calculate discount
    CASE v_coupon.discount_type
        WHEN 'percentage' THEN
            v_discount := p_order_amount * (v_coupon.discount_value / 100);
            IF v_coupon.maximum_discount IS NOT NULL THEN
                v_discount := LEAST(v_discount, v_coupon.maximum_discount);
            END IF;
        WHEN 'fixed_amount' THEN
            v_discount := LEAST(v_coupon.discount_value, p_order_amount);
        WHEN 'free_shipping' THEN
            v_discount := 0; -- Handled separately
    END CASE;
    
    RETURN QUERY SELECT TRUE, v_discount, NULL::TEXT, v_coupon.id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to apply coupon to order
CREATE OR REPLACE FUNCTION apply_coupon_to_order(
    p_order_id UUID,
    p_coupon_code VARCHAR
)
RETURNS TABLE (
    success BOOLEAN,
    discount_amount DECIMAL,
    message TEXT
) AS $$
DECLARE
    v_order RECORD;
    v_validation RECORD;
    v_listing_ids UUID[];
BEGIN
    -- Get order details
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
    AND buyer_id = auth.uid()
    AND status = 'pending_payment';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, 'Order not found or not eligible';
        RETURN;
    END IF;
    
    -- Get listing IDs from order
    SELECT array_agg(listing_id) INTO v_listing_ids
    FROM order_items
    WHERE order_id = p_order_id;
    
    -- Validate coupon
    SELECT * INTO v_validation
    FROM validate_coupon(p_coupon_code, auth.uid(), v_order.subtotal, v_listing_ids);
    
    IF NOT v_validation.is_valid THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL, v_validation.error_message;
        RETURN;
    END IF;
    
    -- Apply discount
    UPDATE orders
    SET discount_amount = v_validation.discount_amount,
        total_amount = subtotal + shipping_cost + tax_amount - v_validation.discount_amount,
        metadata = metadata || jsonb_build_object('coupon_code', p_coupon_code)
    WHERE id = p_order_id;
    
    -- Record usage (will be confirmed on payment)
    INSERT INTO coupon_usage (
        coupon_id,
        user_id,
        order_id,
        discount_amount,
        order_amount
    ) VALUES (
        v_validation.coupon_id,
        auth.uid(),
        p_order_id,
        v_validation.discount_amount,
        v_order.subtotal
    );
    
    RETURN QUERY SELECT TRUE, v_validation.discount_amount, 'Coupon applied successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to award loyalty points
CREATE OR REPLACE FUNCTION award_loyalty_points(
    p_user_id UUID,
    p_points INTEGER,
    p_type VARCHAR,
    p_description TEXT,
    p_order_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_balance INTEGER;
    v_new_balance INTEGER;
BEGIN
    -- Get or create loyalty account
    INSERT INTO loyalty_points (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Get current balance
    SELECT current_balance INTO v_balance
    FROM loyalty_points
    WHERE user_id = p_user_id;
    
    v_new_balance := v_balance + p_points;
    
    -- Update points
    UPDATE loyalty_points
    SET total_earned = total_earned + GREATEST(p_points, 0),
        total_spent = total_spent + ABS(LEAST(p_points, 0)),
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Record transaction
    INSERT INTO points_transactions (
        user_id,
        points,
        transaction_type,
        description,
        order_id,
        balance_after
    ) VALUES (
        p_user_id,
        p_points,
        p_type,
        p_description,
        p_order_id,
        v_new_balance
    );
    
    -- Update tier based on total earned
    UPDATE loyalty_points
    SET tier_name = CASE
            WHEN total_earned >= 10000 THEN 'Platinum'
            WHEN total_earned >= 5000 THEN 'Gold'
            WHEN total_earned >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END,
        tier_level = CASE
            WHEN total_earned >= 10000 THEN 4
            WHEN total_earned >= 5000 THEN 3
            WHEN total_earned >= 1000 THEN 2
            ELSE 1
        END
    WHERE user_id = p_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to award points on order completion
CREATE OR REPLACE FUNCTION award_purchase_points()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Award 1 point per dollar spent
        PERFORM award_loyalty_points(
            NEW.buyer_id,
            FLOOR(NEW.total_amount)::INTEGER,
            'purchase',
            'Points earned from order #' || NEW.order_number,
            NEW.id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER award_points_on_order_complete
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION award_purchase_points();

-- Function to get active promotions for listings
CREATE OR REPLACE FUNCTION get_listing_promotions(p_listing_ids UUID[])
RETURNS TABLE (
    listing_id UUID,
    promotion_type TEXT,
    discount_percentage DECIMAL,
    promotion_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Flash sales
    SELECT 
        unnest(p_listing_ids) as listing_id,
        'flash_sale' as promotion_type,
        CASE 
            WHEN fs.discount_type = 'percentage' THEN fs.discount_value
            ELSE NULL
        END as discount_percentage,
        fs.name as promotion_name
    FROM flash_sales fs
    WHERE fs.is_active = TRUE
    AND NOW() BETWEEN fs.starts_at AND fs.ends_at
    AND (
        fs.target_type = 'all_items'
        OR (fs.target_type = 'specific_items' AND p_listing_ids && fs.listing_ids)
    )
    
    UNION ALL
    
    -- Bundle deals
    SELECT
        unnest(bd.listing_ids) as listing_id,
        'bundle' as promotion_type,
        bd.savings_percentage as discount_percentage,
        bd.name as promotion_name
    FROM bundle_deals bd
    WHERE bd.is_active = TRUE
    AND (bd.valid_until IS NULL OR bd.valid_until > NOW())
    AND bd.listing_ids && p_listing_ids;
END;
$$ LANGUAGE plpgsql STABLE;