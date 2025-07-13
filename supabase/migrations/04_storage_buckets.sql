-- =====================================================
-- Storage Buckets Setup
-- =====================================================

-- Enable the storage extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Note: Storage buckets are created via Supabase Dashboard or CLI
-- This migration documents the required buckets and their policies

-- Required buckets:
-- 1. avatars - for user profile pictures
-- 2. covers - for profile cover images  
-- 3. listings - for product listing images

-- =====================================================
-- Storage Policies (Run these after creating buckets)
-- =====================================================

-- Avatars bucket policies
-- Allow users to upload their own avatar
-- INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
-- VALUES (
--   'avatars',
--   'Users can upload their own avatar',
--   '{"operation": "INSERT"}',
--   'auth.uid() = owner'
-- );

-- Allow public read access to avatars
-- INSERT INTO storage.policies (bucket_id, name, definition)
-- VALUES (
--   'avatars',
--   'Public read access',
--   '{"operation": "SELECT"}'
-- );

-- Covers bucket policies (similar to avatars)
-- Allow users to upload their own cover
-- INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
-- VALUES (
--   'covers',
--   'Users can upload their own cover',
--   '{"operation": "INSERT"}',
--   'auth.uid() = owner'
-- );

-- Listings bucket policies
-- Allow authenticated users to upload listing images
-- INSERT INTO storage.policies (bucket_id, name, definition, check_expression)
-- VALUES (
--   'listings',
--   'Authenticated users can upload',
--   '{"operation": "INSERT"}',
--   'auth.role() = "authenticated"'
-- );

-- Allow public read access to listings
-- INSERT INTO storage.policies (bucket_id, name, definition)
-- VALUES (
--   'listings',
--   'Public read access',
--   '{"operation": "SELECT"}'
-- );

-- =====================================================
-- Helper function to get public URL for storage files
-- =====================================================

CREATE OR REPLACE FUNCTION get_public_url(bucket_name TEXT, file_path TEXT)
RETURNS TEXT AS $$
BEGIN
  -- This returns the public URL pattern for Supabase storage
  -- Replace with your actual Supabase project URL
  RETURN 'https://' || current_setting('app.settings.supabase_project_ref', true) || 
         '.supabase.co/storage/v1/object/public/' || bucket_name || '/' || file_path;
END;
$$ LANGUAGE plpgsql IMMUTABLE;