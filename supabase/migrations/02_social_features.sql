-- =====================================================
-- Phase 2: Social C2C Community Platform - Database Schema
-- =====================================================

-- Create custom types for ratings and achievements
CREATE TYPE rating_type AS ENUM ('seller', 'buyer');
CREATE TYPE achievement_type AS ENUM (
    'first_sale', 'power_seller', 'top_rated', 'verified_seller', 
    'social_butterfly', 'quick_shipper', 'loyal_customer', 'trendsetter'
);

-- =====================================================
-- USER RATINGS & REVIEWS SYSTEM
-- =====================================================

-- User ratings table (seller/buyer ratings)
CREATE TABLE user_ratings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    rated_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    rater_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    review_text TEXT,
    rating_type rating_type NOT NULL,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate ratings for same transaction
    UNIQUE(rated_user_id, rater_user_id, listing_id, rating_type),
    -- Users can't rate themselves
    CHECK (rated_user_id != rater_user_id)
);

-- =====================================================
-- ENHANCED PROFILES TABLE
-- =====================================================

-- Add social and gamification columns to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS seller_rating DECIMAL(3,2) DEFAULT 0.0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS seller_rating_count INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS buyer_rating DECIMAL(3,2) DEFAULT 0.0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS buyer_rating_count INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_sales INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_purchases INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS member_since DATE DEFAULT CURRENT_DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_active TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_views INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verification_badges JSONB DEFAULT '[]';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS seller_level INTEGER DEFAULT 1;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_earnings DECIMAL(12,2) DEFAULT 0.0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS response_time_hours INTEGER DEFAULT 24;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS completion_percentage INTEGER DEFAULT 0;

-- Add constraints for new columns
ALTER TABLE profiles ADD CONSTRAINT seller_rating_range CHECK (seller_rating >= 0 AND seller_rating <= 5);
ALTER TABLE profiles ADD CONSTRAINT buyer_rating_range CHECK (buyer_rating >= 0 AND buyer_rating <= 5);
ALTER TABLE profiles ADD CONSTRAINT seller_level_min CHECK (seller_level >= 1);
ALTER TABLE profiles ADD CONSTRAINT completion_percentage_range CHECK (completion_percentage >= 0 AND completion_percentage <= 100);

-- =====================================================
-- ACHIEVEMENT SYSTEM
-- =====================================================

-- User achievements table
CREATE TABLE user_achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    achievement_type achievement_type NOT NULL,
    level INTEGER DEFAULT 1,
    progress INTEGER DEFAULT 0,
    max_progress INTEGER DEFAULT 100,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    is_visible BOOLEAN DEFAULT TRUE,
    
    UNIQUE(user_id, achievement_type)
);

-- =====================================================
-- TRANSACTIONS TABLE (for rating context)
-- =====================================================

CREATE TABLE transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (buyer_id != seller_id)
);

-- =====================================================
-- PROFILE VIEWS TRACKING
-- =====================================================

CREATE TABLE profile_views (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    viewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent spam views from same user
    UNIQUE(profile_id, viewer_id, DATE(created_at))
);

-- =====================================================
-- SOCIAL ACTIVITY FEED
-- =====================================================

CREATE TABLE user_activities (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    activity_type TEXT NOT NULL, -- 'listed_item', 'made_sale', 'got_review', 'achievement'
    activity_data JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Ratings indexes
CREATE INDEX idx_user_ratings_rated_user ON user_ratings(rated_user_id);
CREATE INDEX idx_user_ratings_rater_user ON user_ratings(rater_user_id);
CREATE INDEX idx_user_ratings_listing ON user_ratings(listing_id);
CREATE INDEX idx_user_ratings_type_rating ON user_ratings(rating_type, rating);

-- Profile social indexes
CREATE INDEX idx_profiles_seller_rating ON profiles(seller_rating DESC) WHERE seller_rating_count > 0;
CREATE INDEX idx_profiles_total_sales ON profiles(total_sales DESC);
CREATE INDEX idx_profiles_last_active ON profiles(last_active DESC);
CREATE INDEX idx_profiles_verification ON profiles USING GIN(verification_badges);

-- Achievement indexes
CREATE INDEX idx_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_achievements_type ON user_achievements(achievement_type);
CREATE INDEX idx_achievements_earned ON user_achievements(earned_at DESC);

-- Activity feed indexes
CREATE INDEX idx_activities_user ON user_activities(user_id);
CREATE INDEX idx_activities_public ON user_activities(is_public, created_at DESC);
CREATE INDEX idx_activities_type ON user_activities(activity_type);

-- Profile views indexes
CREATE INDEX idx_profile_views_profile ON profile_views(profile_id);
CREATE INDEX idx_profile_views_date ON profile_views(created_at DESC);

-- =====================================================
-- FUNCTIONS FOR RATING CALCULATIONS
-- =====================================================

-- Function to update user rating stats
CREATE OR REPLACE FUNCTION update_user_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update seller rating
    IF NEW.rating_type = 'seller' THEN
        UPDATE profiles SET 
            seller_rating = (
                SELECT ROUND(AVG(rating)::numeric, 2)
                FROM user_ratings 
                WHERE rated_user_id = NEW.rated_user_id 
                AND rating_type = 'seller'
            ),
            seller_rating_count = (
                SELECT COUNT(*)
                FROM user_ratings 
                WHERE rated_user_id = NEW.rated_user_id 
                AND rating_type = 'seller'
            )
        WHERE id = NEW.rated_user_id;
        
    -- Update buyer rating
    ELSIF NEW.rating_type = 'buyer' THEN
        UPDATE profiles SET 
            buyer_rating = (
                SELECT ROUND(AVG(rating)::numeric, 2)
                FROM user_ratings 
                WHERE rated_user_id = NEW.rated_user_id 
                AND rating_type = 'buyer'
            ),
            buyer_rating_count = (
                SELECT COUNT(*)
                FROM user_ratings 
                WHERE rated_user_id = NEW.rated_user_id 
                AND rating_type = 'buyer'
            )
        WHERE id = NEW.rated_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for rating updates
CREATE TRIGGER update_rating_stats_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_ratings
    FOR EACH ROW EXECUTE FUNCTION update_user_rating_stats();

-- =====================================================
-- FUNCTION FOR PROFILE VIEW TRACKING
-- =====================================================

CREATE OR REPLACE FUNCTION increment_profile_view()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles 
    SET profile_views = profile_views + 1 
    WHERE id = NEW.profile_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for profile view counting
CREATE TRIGGER increment_profile_view_trigger
    AFTER INSERT ON profile_views
    FOR EACH ROW EXECUTE FUNCTION increment_profile_view();

-- =====================================================
-- FUNCTION FOR ACHIEVEMENT CHECKING
-- =====================================================

CREATE OR REPLACE FUNCTION check_achievements(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
    sales_count INTEGER;
    avg_rating DECIMAL;
    rating_count INTEGER;
BEGIN
    -- Get user stats
    SELECT total_sales, seller_rating, seller_rating_count 
    INTO sales_count, avg_rating, rating_count
    FROM profiles WHERE id = user_uuid;
    
    -- First Sale Achievement
    IF sales_count >= 1 THEN
        INSERT INTO user_achievements (user_id, achievement_type, level)
        VALUES (user_uuid, 'first_sale', 1)
        ON CONFLICT (user_id, achievement_type) DO NOTHING;
    END IF;
    
    -- Power Seller Achievement (10+ sales)
    IF sales_count >= 10 THEN
        INSERT INTO user_achievements (user_id, achievement_type, level)
        VALUES (user_uuid, 'power_seller', 1)
        ON CONFLICT (user_id, achievement_type) DO NOTHING;
    END IF;
    
    -- Top Rated Achievement (4.5+ rating with 5+ reviews)
    IF avg_rating >= 4.5 AND rating_count >= 5 THEN
        INSERT INTO user_achievements (user_id, achievement_type, level)
        VALUES (user_uuid, 'top_rated', 1)
        ON CONFLICT (user_id, achievement_type) DO NOTHING;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE user_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

-- User ratings policies
CREATE POLICY "Ratings are viewable by everyone" ON user_ratings
    FOR SELECT USING (true);

CREATE POLICY "Users can rate others" ON user_ratings
    FOR INSERT WITH CHECK (auth.uid() = rater_user_id);

CREATE POLICY "Users can update their own ratings" ON user_ratings
    FOR UPDATE USING (auth.uid() = rater_user_id);

-- Achievement policies
CREATE POLICY "Achievements are viewable by everyone" ON user_achievements
    FOR SELECT USING (is_visible = true);

CREATE POLICY "Users can view their own achievements" ON user_achievements
    FOR SELECT USING (auth.uid() = user_id);

-- Transaction policies
CREATE POLICY "Users can view their own transactions" ON transactions
    FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Profile view policies
CREATE POLICY "Profile views are trackable" ON profile_views
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view profile view stats" ON profile_views
    FOR SELECT USING (auth.uid() = profile_id);

-- Activity feed policies
CREATE POLICY "Public activities are viewable" ON user_activities
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view their own activities" ON user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own activities" ON user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- SAMPLE ACHIEVEMENTS DATA
-- =====================================================

-- This will be populated by the application logic, but here's the structure
-- Achievement types and their requirements:
-- 'first_sale' - Complete first sale
-- 'power_seller' - 10+ sales
-- 'top_rated' - 4.5+ rating with 5+ reviews  
-- 'verified_seller' - Complete verification process
-- 'social_butterfly' - 50+ followers
-- 'quick_shipper' - Ship within 24 hours 10+ times
-- 'loyal_customer' - 5+ purchases
-- 'trendsetter' - List items in trending categories