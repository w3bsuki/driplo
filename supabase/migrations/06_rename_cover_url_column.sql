-- =====================================================
-- Rename cover_image_url to cover_url for consistency with application code
-- =====================================================

-- Check if the column exists as cover_image_url and rename it
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'cover_image_url'
    ) THEN
        ALTER TABLE profiles RENAME COLUMN cover_image_url TO cover_url;
    END IF;
END $$;

-- Update the handle_new_user function to use the correct column name
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
        cover_url,
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
        NULL, -- cover_url
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