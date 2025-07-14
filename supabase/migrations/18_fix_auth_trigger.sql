-- Fix Authentication Trigger
-- This ensures user profiles are created properly on signup

-- Drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create improved handle_new_user function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
    default_username TEXT;
BEGIN
    -- Generate a default username
    default_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        NEW.raw_user_meta_data->>'name',
        'user_' || substr(NEW.id::text, 1, 8)
    );
    
    -- Ensure username is unique
    WHILE EXISTS (SELECT 1 FROM profiles WHERE username = default_username) LOOP
        default_username := default_username || '_' || substr(md5(random()::text), 1, 4);
    END LOOP;
    
    -- Insert the new profile
    INSERT INTO profiles (id, username, full_name, created_at, updated_at)
    VALUES (
        NEW.id,
        default_username,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        updated_at = NOW();
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail user creation
    RAISE LOG 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create any missing profiles for existing users
INSERT INTO profiles (id, username, full_name, created_at, updated_at)
SELECT 
    u.id,
    'user_' || substr(u.id::text, 1, 8),
    COALESCE(u.raw_user_meta_data->>'full_name', u.email),
    u.created_at,
    NOW()
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;