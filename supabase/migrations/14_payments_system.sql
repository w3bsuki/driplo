-- =====================================================
-- Payment System
-- =====================================================

-- Payment method types
CREATE TYPE payment_method_type AS ENUM ('card', 'bank', 'paypal', 'stripe_link', 'apple_pay', 'google_pay');

-- Payment status types
CREATE TYPE payment_status AS ENUM (
    'pending',
    'processing',
    'requires_action',
    'succeeded',
    'failed',
    'cancelled',
    'refunded',
    'partially_refunded'
);

-- Payment methods stored by users
CREATE TABLE payment_methods (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type payment_method_type NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Display info (safe to store)
    display_name VARCHAR(100), -- 'Visa ending in 4242'
    card_last4 VARCHAR(4),
    card_brand VARCHAR(20), -- 'visa', 'mastercard', etc.
    card_exp_month INTEGER CHECK (card_exp_month >= 1 AND card_exp_month <= 12),
    card_exp_year INTEGER CHECK (card_exp_year >= EXTRACT(YEAR FROM NOW())),
    card_funding VARCHAR(20), -- 'credit', 'debit', 'prepaid'
    
    -- Bank account info
    bank_name VARCHAR(100),
    bank_last4 VARCHAR(4),
    bank_account_type VARCHAR(20), -- 'checking', 'savings'
    
    -- External payment provider references (encrypted)
    stripe_payment_method_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    paypal_account_id VARCHAR(255),
    paypal_email VARCHAR(255),
    
    -- Billing address
    billing_address_id UUID REFERENCES shipping_addresses(id),
    billing_postal_code VARCHAR(20),
    billing_country VARCHAR(2),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ
);

-- Payment transactions
CREATE TABLE payment_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    payment_method_id UUID REFERENCES payment_methods(id),
    
    -- Transaction details
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    status payment_status DEFAULT 'pending' NOT NULL,
    
    -- Processing info
    processor VARCHAR(50) NOT NULL, -- 'stripe', 'paypal', etc.
    processor_transaction_id VARCHAR(255) UNIQUE,
    processor_response JSONB,
    
    -- For Stripe
    stripe_payment_intent_id VARCHAR(255),
    stripe_charge_id VARCHAR(255),
    stripe_refund_id VARCHAR(255),
    client_secret VARCHAR(255), -- For frontend payment confirmation
    
    -- For PayPal
    paypal_order_id VARCHAR(255),
    paypal_capture_id VARCHAR(255),
    paypal_refund_id VARCHAR(255),
    
    -- Additional info
    description TEXT,
    statement_descriptor VARCHAR(22), -- What appears on bank statement
    failure_code VARCHAR(50),
    failure_message TEXT,
    
    -- Fees
    platform_fee DECIMAL(10,2) DEFAULT 0,
    processor_fee DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2), -- amount - fees
    
    -- 3D Secure / Authentication
    authentication_required BOOLEAN DEFAULT FALSE,
    authenticated BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ
);

-- Refunds table
CREATE TABLE payment_refunds (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    transaction_id UUID REFERENCES payment_transactions(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    
    -- Refund details
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    reason VARCHAR(100),
    notes TEXT,
    status payment_status DEFAULT 'pending',
    
    -- Processor info
    processor_refund_id VARCHAR(255),
    processor_response JSONB,
    
    -- Metadata
    initiated_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- Payout settings for sellers
CREATE TABLE seller_payout_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Payout method
    payout_method VARCHAR(50) DEFAULT 'bank_transfer', -- 'bank_transfer', 'paypal'
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Bank details (encrypted)
    bank_account_id VARCHAR(255), -- Stripe Connect account ID
    bank_name VARCHAR(100),
    bank_last4 VARCHAR(4),
    bank_routing_number_last4 VARCHAR(4),
    
    -- PayPal
    paypal_email VARCHAR(255),
    paypal_account_verified BOOLEAN DEFAULT FALSE,
    
    -- Payout schedule
    payout_schedule VARCHAR(20) DEFAULT 'weekly', -- 'daily', 'weekly', 'monthly'
    minimum_payout_amount DECIMAL(10,2) DEFAULT 10.00,
    
    -- Tax info
    tax_id VARCHAR(50),
    tax_id_type VARCHAR(20), -- 'ssn', 'ein', etc.
    tax_verified BOOLEAN DEFAULT FALSE,
    
    -- Stripe Connect
    stripe_connect_account_id VARCHAR(255),
    stripe_connect_onboarding_complete BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Platform fees configuration
CREATE TABLE platform_fee_rules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Fee structure
    percentage_fee DECIMAL(5,2) DEFAULT 5.00, -- 5%
    fixed_fee DECIMAL(10,2) DEFAULT 0.30, -- $0.30
    
    -- Conditions
    min_order_amount DECIMAL(10,2),
    max_order_amount DECIMAL(10,2),
    category_ids UUID[] DEFAULT '{}',
    seller_level_min INTEGER,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0, -- Higher priority rules apply first
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_payout_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_fee_rules ENABLE ROW LEVEL SECURITY;

-- Payment method policies
CREATE POLICY "Users can view their payment methods" ON payment_methods
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their payment methods" ON payment_methods
    FOR ALL USING (auth.uid() = user_id);

-- Transaction policies
CREATE POLICY "Users can view their transactions" ON payment_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = payment_transactions.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

-- Refund policies
CREATE POLICY "Users can view refunds for their orders" ON payment_refunds
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = payment_refunds.order_id
            AND auth.uid() IN (orders.buyer_id, orders.seller_id)
        )
    );

-- Payout settings policies
CREATE POLICY "Sellers can view their payout settings" ON seller_payout_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Sellers can manage their payout settings" ON seller_payout_settings
    FOR ALL USING (auth.uid() = user_id);

-- Platform fee rules (public read)
CREATE POLICY "Fee rules are public" ON platform_fee_rules
    FOR SELECT USING (is_active = TRUE);

-- Indexes
CREATE INDEX idx_payment_methods_user ON payment_methods(user_id);
CREATE INDEX idx_payment_methods_default ON payment_methods(user_id, is_default) WHERE is_default = TRUE;
CREATE INDEX idx_transactions_order ON payment_transactions(order_id);
CREATE INDEX idx_transactions_status ON payment_transactions(status);
CREATE INDEX idx_transactions_processor ON payment_transactions(processor, processor_transaction_id);
CREATE INDEX idx_refunds_transaction ON payment_refunds(transaction_id);
CREATE INDEX idx_refunds_order ON payment_refunds(order_id);

-- Function to ensure single default payment method
CREATE OR REPLACE FUNCTION ensure_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE payment_methods
        SET is_default = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id
        AND is_default = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for single default payment method
CREATE TRIGGER maintain_single_default_payment
    BEFORE INSERT OR UPDATE OF is_default ON payment_methods
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION ensure_single_default_payment_method();

-- Function to calculate platform fees
CREATE OR REPLACE FUNCTION calculate_platform_fee(
    p_order_amount DECIMAL,
    p_category_id UUID DEFAULT NULL,
    p_seller_id UUID DEFAULT NULL
)
RETURNS TABLE (
    fee_amount DECIMAL,
    fee_percentage DECIMAL,
    fee_fixed DECIMAL,
    net_amount DECIMAL
) AS $$
DECLARE
    v_percentage DECIMAL;
    v_fixed DECIMAL;
    v_fee_total DECIMAL;
    v_seller_level INTEGER;
BEGIN
    -- Get seller level if provided
    IF p_seller_id IS NOT NULL THEN
        SELECT seller_level INTO v_seller_level
        FROM profiles
        WHERE id = p_seller_id;
    END IF;
    
    -- Get applicable fee rule
    SELECT percentage_fee, fixed_fee
    INTO v_percentage, v_fixed
    FROM platform_fee_rules
    WHERE is_active = TRUE
    AND (min_order_amount IS NULL OR p_order_amount >= min_order_amount)
    AND (max_order_amount IS NULL OR p_order_amount <= max_order_amount)
    AND (category_ids = '{}' OR p_category_id = ANY(category_ids))
    AND (seller_level_min IS NULL OR v_seller_level >= seller_level_min)
    ORDER BY priority DESC
    LIMIT 1;
    
    -- Default fees if no rule found
    IF NOT FOUND THEN
        v_percentage := 5.00; -- 5%
        v_fixed := 0.30; -- $0.30
    END IF;
    
    -- Calculate total fee
    v_fee_total := ROUND((p_order_amount * v_percentage / 100) + v_fixed, 2);
    
    RETURN QUERY
    SELECT 
        v_fee_total,
        v_percentage,
        v_fixed,
        p_order_amount - v_fee_total;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to process payment
CREATE OR REPLACE FUNCTION process_payment(
    p_order_id UUID,
    p_payment_method_id UUID,
    p_processor VARCHAR,
    p_processor_transaction_id VARCHAR
)
RETURNS UUID AS $$
DECLARE
    v_transaction_id UUID;
    v_order RECORD;
    v_fees RECORD;
BEGIN
    -- Get order details
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
    AND status = 'pending_payment';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found or not pending payment';
    END IF;
    
    -- Calculate fees
    SELECT * INTO v_fees
    FROM calculate_platform_fee(v_order.total_amount, NULL, v_order.seller_id);
    
    -- Create transaction record
    INSERT INTO payment_transactions (
        order_id,
        payment_method_id,
        amount,
        processor,
        processor_transaction_id,
        platform_fee,
        net_amount,
        status
    ) VALUES (
        p_order_id,
        p_payment_method_id,
        v_order.total_amount,
        p_processor,
        p_processor_transaction_id,
        v_fees.fee_amount,
        v_fees.net_amount,
        'processing'
    ) RETURNING id INTO v_transaction_id;
    
    -- Update order status
    UPDATE orders
    SET status = 'payment_processing',
        payment_method = p_processor
    WHERE id = p_order_id;
    
    -- Update payment method last used
    UPDATE payment_methods
    SET last_used_at = NOW()
    WHERE id = p_payment_method_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to confirm payment
CREATE OR REPLACE FUNCTION confirm_payment(
    p_transaction_id UUID,
    p_processor_response JSONB DEFAULT '{}'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_order_id UUID;
BEGIN
    -- Update transaction
    UPDATE payment_transactions
    SET status = 'succeeded',
        processed_at = NOW(),
        processor_response = p_processor_response
    WHERE id = p_transaction_id
    RETURNING order_id INTO v_order_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Update order status
    UPDATE orders
    SET status = 'paid',
        payment_status = 'completed',
        paid_at = NOW()
    WHERE id = v_order_id;
    
    -- Trigger inventory reduction (handled by order trigger)
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert default platform fee rule
INSERT INTO platform_fee_rules (
    name,
    description,
    percentage_fee,
    fixed_fee,
    priority
) VALUES (
    'Default Platform Fee',
    'Standard fee for all transactions',
    5.00,
    0.30,
    0
) ON CONFLICT DO NOTHING;