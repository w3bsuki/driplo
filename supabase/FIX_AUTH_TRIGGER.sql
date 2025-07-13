-- =====================================================
-- FIX: Authentication Trigger for User Registration
-- =====================================================

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create a more robust function that handles errors gracefully
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_username TEXT;
BEGIN
    -- Generate default username
    default_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        'user_' || substr(NEW.id::text, 1, 8)
    );

    -- Try to insert the profile
    BEGIN
        INSERT INTO public.profiles (
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
            completion_percentage,
            follower_count,
            following_count,
            is_verified,
            created_at,
            updated_at
        )
        VALUES (
            NEW.id,
            default_username,
            COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
            COALESCE(NEW.email, ''),
            COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
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
            0,
            0,
            0,
            false,
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN unique_violation THEN
            -- If username already exists, try with a random suffix
            default_username := default_username || '_' || substr(md5(random()::text), 1, 4);
            
            INSERT INTO public.profiles (
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
                completion_percentage,
                follower_count,
                following_count,
                is_verified,
                created_at,
                updated_at
            )
            VALUES (
                NEW.id,
                default_username,
                COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
                COALESCE(NEW.email, ''),
                COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
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
                0,
                0,
                0,
                false,
                NOW(),
                NOW()
            );
        WHEN OTHERS THEN
            -- Log the error but don't fail the auth
            RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users table
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;

-- Ensure the trigger function can insert into profiles
ALTER FUNCTION handle_new_user() OWNER TO postgres;

-- Test the trigger works by checking if it exists
SELECT 
    n.nspname as schema_name,
    t.tgname as trigger_name,
    p.proname as function_name,
    c.relname as table_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgname = 'on_auth_user_created';