-- Run these SQL commands in your Supabase SQL Editor

-- 1. First, create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username VARCHAR(30) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    location VARCHAR(100),
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    listings_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    icon VARCHAR(10) DEFAULT '📦',
    description TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create listings table
CREATE TABLE IF NOT EXISTS listings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    condition VARCHAR(20) NOT NULL CHECK (condition IN ('new', 'like_new', 'good', 'fair', 'poor')),
    size VARCHAR(50),
    brand VARCHAR(100),
    color VARCHAR(50),
    images JSONB DEFAULT '[]'::jsonb,
    location VARCHAR(255) NOT NULL,
    shipping_type VARCHAR(20) DEFAULT 'standard' CHECK (shipping_type IN ('standard', 'express', 'pickup_only')),
    shipping_cost DECIMAL(10,2) DEFAULT 0 CHECK (shipping_cost >= 0),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'sold', 'reserved', 'inactive', 'deleted')),
    view_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sold_at TIMESTAMPTZ
);

-- 4. Insert sample categories
INSERT INTO categories (name, slug, icon, sort_order) VALUES
    ('Women', 'women', '👗', 1),
    ('Men', 'men', '👔', 2),
    ('Kids', 'kids', '👶', 3),
    ('Shoes', 'shoes', '👟', 4),
    ('Bags', 'bags', '👜', 5),
    ('Accessories', 'accessories', '💍', 6),
    ('Beauty', 'beauty', '💄', 7),
    ('Home', 'home', '🏠', 8),
    ('Electronics', 'electronics', '📱', 9),
    ('Sports', 'sports', '⚽', 10)
ON CONFLICT (name) DO NOTHING;

-- 5. Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

-- 6. Create policies
CREATE POLICY IF NOT EXISTS "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "Categories are public" ON categories FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "Listings are viewable by everyone" ON listings FOR SELECT USING (status IN ('active', 'sold', 'reserved'));
CREATE POLICY IF NOT EXISTS "Users can create their own listings" ON listings FOR INSERT WITH CHECK (auth.uid() = seller_id);
CREATE POLICY IF NOT EXISTS "Users can update their own listings" ON listings FOR UPDATE USING (auth.uid() = seller_id);