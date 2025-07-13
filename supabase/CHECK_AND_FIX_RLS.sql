-- =====================================================
-- CHECK AND FIX RLS POLICIES
-- =====================================================

-- First, check current RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'profiles';

-- Temporarily disable RLS to test (DO NOT USE IN PRODUCTION)
-- ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Drop all existing policies on profiles to start fresh
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Create comprehensive policies
-- Allow anyone to view profiles
CREATE POLICY "Public profiles are viewable" 
ON profiles FOR SELECT 
USING (true);

-- Allow users to insert their own profile
CREATE POLICY "Users can create own profile" 
ON profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- IMPORTANT: Allow the service role (used by triggers) to do anything
CREATE POLICY "Service role has full access" 
ON profiles 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Grant execute permission on the function to postgres and service_role
GRANT EXECUTE ON FUNCTION handle_new_user() TO postgres, service_role;

-- Ensure auth schema permissions
GRANT USAGE ON SCHEMA auth TO postgres, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres, service_role;

-- Test by checking policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;