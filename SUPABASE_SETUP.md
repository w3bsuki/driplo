# Supabase Setup Guide

## Complete Database Schema

Copy and paste this entire SQL script into your Supabase SQL Editor:

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE listing_status AS ENUM ('draft', 'active', 'sold', 'inactive');
CREATE TYPE listing_condition AS ENUM ('new_with_tags', 'like_new', 'good', 'fair', 'poor');

-- Profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    website TEXT,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    listings_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$')
);

-- Categories table
CREATE TABLE categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Listings table
CREATE TABLE listings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    currency TEXT DEFAULT 'USD' NOT NULL,
    category_id UUID REFERENCES categories(id) NOT NULL,
    subcategory_id UUID REFERENCES categories(id),
    brand TEXT,
    size TEXT,
    condition listing_condition NOT NULL,
    colors TEXT[] DEFAULT '{}',
    materials TEXT[] DEFAULT '{}',
    images JSONB DEFAULT '[]',
    status listing_status DEFAULT 'draft',
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    is_negotiable BOOLEAN DEFAULT FALSE,
    shipping_included BOOLEAN DEFAULT FALSE,
    shipping_cost DECIMAL(10,2) CHECK (shipping_cost >= 0),
    location TEXT,
    dimensions JSONB,
    weight DECIMAL(10,3) CHECK (weight >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sold_at TIMESTAMPTZ,
    
    CONSTRAINT title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 100),
    CONSTRAINT description_length CHECK (char_length(description) >= 10 AND char_length(description) <= 2000)
);

-- User follows table (for following other users)
CREATE TABLE user_follows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- Listing likes table
CREATE TABLE listing_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    listing_id UUID REFERENCES listings(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, listing_id)
);

-- Create indexes for performance
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_listings_seller_id ON listings(seller_id);
CREATE INDEX idx_listings_category_id ON listings(category_id);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_created_at ON listings(created_at DESC);
CREATE INDEX idx_listings_price ON listings(price);
CREATE INDEX idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following_id ON user_follows(following_id);
CREATE INDEX idx_listing_likes_user_id ON listing_likes(user_id);
CREATE INDEX idx_listing_likes_listing_id ON listing_likes(listing_id);

-- Full text search index for listings
CREATE INDEX idx_listings_search ON listings USING GIN(to_tsvector('english', title || ' ' || description || ' ' || COALESCE(brand, '')));

-- Create functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_listings_updated_at BEFORE UPDATE ON listings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, username, full_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        NEW.raw_user_meta_data->>'full_name'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to update follower counts
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Increment following count for follower
        UPDATE profiles SET following_count = following_count + 1 
        WHERE id = NEW.follower_id;
        
        -- Increment followers count for followed user
        UPDATE profiles SET followers_count = followers_count + 1 
        WHERE id = NEW.following_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrement following count for follower
        UPDATE profiles SET following_count = following_count - 1 
        WHERE id = OLD.follower_id;
        
        -- Decrement followers count for followed user
        UPDATE profiles SET followers_count = followers_count - 1 
        WHERE id = OLD.following_id;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for follow counts
CREATE TRIGGER update_follow_counts_trigger
    AFTER INSERT OR DELETE ON user_follows
    FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Function to update listing counts
CREATE OR REPLACE FUNCTION update_listing_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE profiles SET listings_count = listings_count + 1 
        WHERE id = NEW.seller_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE profiles SET listings_count = listings_count - 1 
        WHERE id = OLD.seller_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for listing counts
CREATE TRIGGER update_listing_counts_trigger
    AFTER INSERT OR DELETE ON listings
    FOR EACH ROW EXECUTE FUNCTION update_listing_counts();

-- Function to update like counts
CREATE OR REPLACE FUNCTION update_like_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE listings SET like_count = like_count + 1 
        WHERE id = NEW.listing_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE listings SET like_count = like_count - 1 
        WHERE id = OLD.listing_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for like counts
CREATE TRIGGER update_like_counts_trigger
    AFTER INSERT OR DELETE ON listing_likes
    FOR EACH ROW EXECUTE FUNCTION update_like_counts();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE listing_likes ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Categories policies (public read, admin write)
CREATE POLICY "Categories are viewable by everyone" ON categories
    FOR SELECT USING (is_active = true);

-- Listings policies
CREATE POLICY "Published listings are viewable by everyone" ON listings
    FOR SELECT USING (status = 'active');

CREATE POLICY "Users can view their own listings" ON listings
    FOR SELECT USING (auth.uid() = seller_id);

CREATE POLICY "Users can create their own listings" ON listings
    FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Users can update their own listings" ON listings
    FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "Users can delete their own listings" ON listings
    FOR DELETE USING (auth.uid() = seller_id);

-- User follows policies
CREATE POLICY "User follows are viewable by everyone" ON user_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON user_follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others" ON user_follows
    FOR DELETE USING (auth.uid() = follower_id);

-- Listing likes policies
CREATE POLICY "Listing likes are viewable by everyone" ON listing_likes
    FOR SELECT USING (true);

CREATE POLICY "Users can like listings" ON listing_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike listings" ON listing_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Insert initial categories
INSERT INTO categories (name, slug, description, sort_order) VALUES
('Women', 'women', 'Women''s clothing and accessories', 1),
('Men', 'men', 'Men''s clothing and accessories', 2),
('Kids', 'kids', 'Children''s clothing and accessories', 3),
('Home', 'home', 'Home decor and accessories', 4),
('Beauty', 'beauty', 'Beauty and personal care products', 5),
('Electronics', 'electronics', 'Electronics and gadgets', 6);

-- Insert subcategories for Women
INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Tops', 'women-tops', id, 1 FROM categories WHERE slug = 'women';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Dresses', 'women-dresses', id, 2 FROM categories WHERE slug = 'women';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Bottoms', 'women-bottoms', id, 3 FROM categories WHERE slug = 'women';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Shoes', 'women-shoes', id, 4 FROM categories WHERE slug = 'women';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Bags', 'women-bags', id, 5 FROM categories WHERE slug = 'women';

-- Insert subcategories for Men
INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Shirts', 'men-shirts', id, 1 FROM categories WHERE slug = 'men';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'T-shirts', 'men-tshirts', id, 2 FROM categories WHERE slug = 'men';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Pants', 'men-pants', id, 3 FROM categories WHERE slug = 'men';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Shoes', 'men-shoes', id, 4 FROM categories WHERE slug = 'men';

INSERT INTO categories (name, slug, parent_id, sort_order) 
SELECT 'Accessories', 'men-accessories', id, 5 FROM categories WHERE slug = 'men';
```

## Authentication Configuration

After running the SQL schema, configure authentication in your Supabase dashboard:

### 1. Go to Authentication → Settings

### 2. Configure Site URLs
- **Site URL:** `http://localhost:5190`
- **Redirect URLs:** 
  - `http://localhost:5190/auth/callback`
  - `http://localhost:5190/**` (for development)

### 3. Enable Authentication Providers
- ✅ **Email** (already enabled by default)
- ✅ **Google OAuth** (optional - get keys from Google Console)
- ✅ **GitHub OAuth** (optional - get keys from GitHub)

### 4. Email Settings (Optional)
- Configure custom SMTP if needed
- Or use Supabase's built-in email service

## What This Setup Provides

### ✅ Complete Authentication System
- User registration with automatic profile creation
- Email/password login
- OAuth providers (Google, GitHub)
- Secure logout
- Session management

### ✅ Database Structure
- **profiles**: User profiles with social features
- **categories**: Product categories and subcategories  
- **listings**: User-created product listings/ads
- **user_follows**: Social following system
- **listing_likes**: Favorites/likes for listings

### ✅ Security Features
- Row Level Security (RLS) on all tables
- Users can only edit their own data
- Public data is readable by everyone
- Secure triggers for automatic data updates

### ✅ Performance Optimizations
- Database indexes on frequently queried columns
- Full-text search on listings
- Automatic timestamp updates
- Optimized foreign key relationships

## Next Steps

1. **Run the SQL schema** in Supabase SQL Editor
2. **Configure authentication settings** as described above
3. **Test the setup** by visiting `http://localhost:5190/login`
4. **Register a new user** to verify automatic profile creation
5. **Ready to build** sell flow and user profiles!

## Environment Variables

Your `.env.local` is already configured with:
```env
PUBLIC_SUPABASE_URL=https://ibbwcfrvuertmlbpuofm.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Everything is ready to go! 🚀