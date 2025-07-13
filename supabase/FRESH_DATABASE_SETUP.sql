-- =====================================================
-- THREADLY MARKETPLACE - COMPLETE DATABASE SETUP
-- Clean, comprehensive database initialization
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- PROFILES TABLE (Source of Truth for Users)
-- =====================================================
CREATE TABLE profiles (
    -- Core fields
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    bio TEXT,
    location TEXT,
    website TEXT,
    
    -- Social stats
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    
    -- Seller stats
    seller_rating DECIMAL(3,2) DEFAULT 0.0 CHECK (seller_rating >= 0 AND seller_rating <= 5),
    seller_rating_count INTEGER DEFAULT 0,
    total_sales INTEGER DEFAULT 0,
    total_earnings DECIMAL(12,2) DEFAULT 0.0,
    seller_level INTEGER DEFAULT 1 CHECK (seller_level >= 1),
    
    -- Buyer stats
    buyer_rating DECIMAL(3,2) DEFAULT 0.0 CHECK (buyer_rating >= 0 AND buyer_rating <= 5),
    buyer_rating_count INTEGER DEFAULT 0,
    total_purchases INTEGER DEFAULT 0,
    
    -- Profile metadata
    member_since DATE DEFAULT CURRENT_DATE,
    last_active TIMESTAMPTZ DEFAULT NOW(),
    profile_views INTEGER DEFAULT 0,
    response_time_hours INTEGER DEFAULT 24,
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    
    -- Verification and features
    is_verified BOOLEAN DEFAULT FALSE,
    verification_badges JSONB DEFAULT '[]'::jsonb,
    social_links JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- CATEGORIES TABLE
-- =====================================================
CREATE TABLE categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_name TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- LISTINGS TABLE
-- =====================================================
CREATE TABLE listings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    currency TEXT DEFAULT 'USD',
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    subcategory_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    
    -- Item details
    condition TEXT CHECK (condition IN ('new', 'like_new', 'excellent', 'good', 'fair')),
    size TEXT,
    brand TEXT,
    color TEXT,
    material TEXT,
    
    -- Media
    images JSONB DEFAULT '[]'::jsonb,
    video_url TEXT,
    
    -- Location
    location_city TEXT,
    location_country TEXT,
    ships_worldwide BOOLEAN DEFAULT FALSE,
    
    -- Stats
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    
    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'sold', 'reserved', 'deleted')),
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- SEO
    slug TEXT UNIQUE,
    tags TEXT[],
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    sold_at TIMESTAMPTZ
);

-- =====================================================
-- FAVORITES TABLE (Users can favorite listings)
-- =====================================================
CREATE TABLE favorites (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, listing_id)
);

-- =====================================================
-- USER FOLLOWS TABLE
-- =====================================================
CREATE TABLE user_follows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- =====================================================
-- TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'cancelled', 'refunded')),
    payment_method TEXT,
    stripe_payment_id TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (buyer_id != seller_id)
);

-- =====================================================
-- USER RATINGS TABLE
-- =====================================================
CREATE TYPE rating_type AS ENUM ('seller', 'buyer');

CREATE TABLE user_ratings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    rated_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    rater_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    review_text TEXT,
    rating_type rating_type NOT NULL,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(rated_user_id, rater_user_id, transaction_id, rating_type),
    CHECK (rated_user_id != rater_user_id)
);

-- =====================================================
-- MESSAGES TABLE
-- =====================================================
CREATE TABLE messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (sender_id != recipient_id)
);

-- =====================================================
-- CORE FUNCTIONS AND TRIGGERS
-- =====================================================

-- Handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (
        id, 
        username, 
        full_name,
        email,
        avatar_url,
        seller_rating,
        seller_rating_count,
        buyer_rating,
        buyer_rating_count,
        total_sales,
        total_purchases,
        member_since,
        last_active,
        profile_views,
        verification_badges,
        social_links,
        seller_level,
        total_earnings,
        response_time_hours,
        completion_percentage
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        NEW.raw_user_meta_data->>'full_name',
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url',
        0.0,
        0,
        0.0,
        0,
        0,
        0,
        CURRENT_DATE,
        NOW(),
        0,
        '[]'::jsonb,
        '{}'::jsonb,
        1,
        0.0,
        24,
        0
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_listings_updated_at BEFORE UPDATE ON listings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update listing stats when favorited
CREATE OR REPLACE FUNCTION update_listing_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE listings 
        SET like_count = like_count + 1 
        WHERE id = NEW.listing_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE listings 
        SET like_count = GREATEST(0, like_count - 1) 
        WHERE id = OLD.listing_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_listing_favorites
    AFTER INSERT OR DELETE ON favorites
    FOR EACH ROW EXECUTE FUNCTION update_listing_stats();

-- Update follow counts
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE profiles SET follower_count = follower_count + 1 WHERE id = NEW.following_id;
        UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE profiles SET follower_count = GREATEST(0, follower_count - 1) WHERE id = OLD.following_id;
        UPDATE profiles SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_follow_counts_trigger
    AFTER INSERT OR DELETE ON user_follows
    FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Categories policies
CREATE POLICY "Categories are viewable by everyone" ON categories
    FOR SELECT USING (true);

-- Listings policies
CREATE POLICY "Listings are viewable by everyone" ON listings
    FOR SELECT USING (status = 'active' OR seller_id = auth.uid());

CREATE POLICY "Users can create listings" ON listings
    FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Users can update own listings" ON listings
    FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "Users can delete own listings" ON listings
    FOR DELETE USING (auth.uid() = seller_id);

-- Favorites policies
CREATE POLICY "Users can view own favorites" ON favorites
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own favorites" ON favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON favorites
    FOR DELETE USING (auth.uid() = user_id);

-- User follows policies
CREATE POLICY "Follows are viewable by everyone" ON user_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can create follows" ON user_follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own follows" ON user_follows
    FOR DELETE USING (auth.uid() = follower_id);

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid() IN (buyer_id, seller_id));

CREATE POLICY "Buyers can create transactions" ON transactions
    FOR INSERT WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Users can update own transactions" ON transactions
    FOR UPDATE USING (auth.uid() IN (buyer_id, seller_id));

-- Ratings policies
CREATE POLICY "Ratings are viewable by everyone" ON user_ratings
    FOR SELECT USING (true);

CREATE POLICY "Users can create ratings for their transactions" ON user_ratings
    FOR INSERT WITH CHECK (
        auth.uid() = rater_user_id AND
        EXISTS (
            SELECT 1 FROM transactions
            WHERE id = transaction_id
            AND (buyer_id = auth.uid() OR seller_id = auth.uid())
        )
    );

-- Messages policies
CREATE POLICY "Users can view own messages" ON messages
    FOR SELECT USING (auth.uid() IN (sender_id, recipient_id));

CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Recipients can update message read status" ON messages
    FOR UPDATE USING (auth.uid() = recipient_id);

-- =====================================================
-- STORAGE BUCKETS
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('avatars', 'avatars', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
    ('covers', 'covers', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
    ('listings', 'listings', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own avatar" ON storage.objects
    FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own avatar" ON storage.objects
    FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Similar policies for covers and listings buckets
CREATE POLICY "Cover images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'covers');

CREATE POLICY "Users can manage own covers" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'covers' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Listing images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'listings');

CREATE POLICY "Users can manage own listing images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'listings' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_listings_seller_id ON listings(seller_id);
CREATE INDEX idx_listings_category_id ON listings(category_id);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_created_at ON listings(created_at DESC);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_listing_id ON favorites(listing_id);
CREATE INDEX idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following_id ON user_follows(following_id);
CREATE INDEX idx_transactions_buyer_id ON transactions(buyer_id);
CREATE INDEX idx_transactions_seller_id ON transactions(seller_id);
CREATE INDEX idx_messages_recipient_id ON messages(recipient_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);