-- =====================================================
-- Fix existing user profiles that were created with incomplete data
-- =====================================================

-- Update any existing profiles that have NULL or missing values
UPDATE profiles
SET 
    seller_rating = COALESCE(seller_rating, 0.0),
    seller_rating_count = COALESCE(seller_rating_count, 0),
    buyer_rating = COALESCE(buyer_rating, 0.0),
    buyer_rating_count = COALESCE(buyer_rating_count, 0),
    total_sales = COALESCE(total_sales, 0),
    total_purchases = COALESCE(total_purchases, 0),
    member_since = COALESCE(member_since, CURRENT_DATE),
    last_active = COALESCE(last_active, NOW()),
    profile_views = COALESCE(profile_views, 0),
    verification_badges = COALESCE(verification_badges, '[]'::jsonb),
    social_links = COALESCE(social_links, '{}'::jsonb),
    seller_level = COALESCE(seller_level, 1),
    total_earnings = COALESCE(total_earnings, 0.0),
    response_time_hours = COALESCE(response_time_hours, 24),
    completion_percentage = COALESCE(completion_percentage, 0)
WHERE 
    seller_rating IS NULL 
    OR seller_rating_count IS NULL
    OR buyer_rating IS NULL
    OR buyer_rating_count IS NULL
    OR total_sales IS NULL
    OR total_purchases IS NULL
    OR member_since IS NULL
    OR last_active IS NULL
    OR profile_views IS NULL
    OR verification_badges IS NULL
    OR social_links IS NULL
    OR seller_level IS NULL
    OR total_earnings IS NULL
    OR response_time_hours IS NULL
    OR completion_percentage IS NULL;