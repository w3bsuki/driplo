-- =====================================================
-- FIX LISTINGS TABLE AND POPULATE CATEGORIES
-- =====================================================

-- 1. First, populate categories
INSERT INTO categories (id, name, slug, description, icon_name, display_order, is_active) VALUES
-- Main categories
('550e8400-e29b-41d4-a716-446655440001', 'Women', 'women', 'Women''s fashion and accessories', 'woman', 1, true),
('550e8400-e29b-41d4-a716-446655440002', 'Men', 'men', 'Men''s fashion and accessories', 'man', 2, true),
('550e8400-e29b-41d4-a716-446655440003', 'Kids', 'kids', 'Children''s clothing and accessories', 'baby', 3, true),
('550e8400-e29b-41d4-a716-446655440004', 'Accessories', 'accessories', 'Bags, jewelry, and more', 'gem', 4, true),
('550e8400-e29b-41d4-a716-446655440005', 'Shoes', 'shoes', 'Footwear for all', 'footprints', 5, true),
('550e8400-e29b-41d4-a716-446655440006', 'Beauty', 'beauty', 'Beauty and cosmetics', 'sparkles', 6, true),
('550e8400-e29b-41d4-a716-446655440007', 'Home', 'home', 'Home decor and lifestyle', 'home', 7, true),
('550e8400-e29b-41d4-a716-446655440008', 'Vintage', 'vintage', 'Vintage and collectibles', 'clock', 8, true)
ON CONFLICT (id) DO NOTHING;

-- 2. Add some subcategories
INSERT INTO categories (id, name, slug, description, parent_id, display_order, is_active) VALUES
-- Women's subcategories
('550e8400-e29b-41d4-a716-446655440101', 'Dresses', 'women-dresses', 'Women''s dresses', '550e8400-e29b-41d4-a716-446655440001', 1, true),
('550e8400-e29b-41d4-a716-446655440102', 'Tops', 'women-tops', 'Women''s tops and blouses', '550e8400-e29b-41d4-a716-446655440001', 2, true),
('550e8400-e29b-41d4-a716-446655440103', 'Bottoms', 'women-bottoms', 'Women''s pants and skirts', '550e8400-e29b-41d4-a716-446655440001', 3, true),
('550e8400-e29b-41d4-a716-446655440104', 'Outerwear', 'women-outerwear', 'Women''s coats and jackets', '550e8400-e29b-41d4-a716-446655440001', 4, true),
-- Men's subcategories
('550e8400-e29b-41d4-a716-446655440201', 'Shirts', 'men-shirts', 'Men''s shirts', '550e8400-e29b-41d4-a716-446655440002', 1, true),
('550e8400-e29b-41d4-a716-446655440202', 'Pants', 'men-pants', 'Men''s pants and jeans', '550e8400-e29b-41d4-a716-446655440002', 2, true),
('550e8400-e29b-41d4-a716-446655440203', 'Outerwear', 'men-outerwear', 'Men''s coats and jackets', '550e8400-e29b-41d4-a716-446655440002', 3, true),
('550e8400-e29b-41d4-a716-446655440204', 'Suits', 'men-suits', 'Men''s suits and blazers', '550e8400-e29b-41d4-a716-446655440002', 4, true)
ON CONFLICT (id) DO NOTHING;

-- 3. Fix the condition enum to include 'poor'
ALTER TABLE listings DROP CONSTRAINT IF EXISTS listings_condition_check;
ALTER TABLE listings ADD CONSTRAINT listings_condition_check 
  CHECK (condition IN ('new', 'like_new', 'excellent', 'good', 'fair', 'poor'));

-- 4. Check what we have
SELECT 'Categories created:' as info, COUNT(*) as count FROM categories WHERE parent_id IS NULL
UNION ALL
SELECT 'Subcategories created:', COUNT(*) FROM categories WHERE parent_id IS NOT NULL;