-- =====================================================
-- Fix user registration trigger to properly initialize all profile columns
-- This corrects the regression introduced in 04_simple_user_trigger.sql
-- =====================================================

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create updated function to handle new user registration with all profile columns
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (
        id, 
        username, 
        full_name,
        seller_rating,
        seller_rating_count,
        buyer_rating,
        buyer_rating_count,
        total_sales,
        total_purchases,
        member_since,
        last_active,
        profile_views,
        cover_image_url,
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
        0.0,  -- seller_rating
        0,    -- seller_rating_count
        0.0,  -- buyer_rating
        0,    -- buyer_rating_count
        0,    -- total_sales
        0,    -- total_purchases
        CURRENT_DATE,  -- member_since
        NOW(), -- last_active
        0,    -- profile_views
        NULL, -- cover_image_url
        '[]'::jsonb,  -- verification_badges
        '{}'::jsonb,  -- social_links
        1,    -- seller_level
        0.0,  -- total_earnings
        24,   -- response_time_hours
        0     -- completion_percentage
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Also add a migration to rename cover_url to cover_image_url in the code
-- Note: The database column is correctly named cover_image_url
-- This comment is for developers to update their application code accordingly