import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabase';

export const load: PageServerLoad = async () => {
  // Get main categories with product counts
  const { data: categories } = await supabase
    .from('categories')
    .select(`
      *,
      product_count:listings(count)
    `)
    .is('parent_id', null)
    .eq('is_active', true)
    .order('sort_order')
    .order('name');

  // Get featured listings
  const { data: featuredListings } = await supabase
    .from('listings')
    .select(`
      *,
      seller:profiles!seller_id(username, avatar_url)
    `)
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .limit(16);

  // Get most viewed listings
  const { data: popularListings } = await supabase
    .from('listings')
    .select(`
      *,
      seller:profiles!seller_id(username, avatar_url)
    `)
    .eq('status', 'active')
    .order('view_count', { ascending: false })
    .limit(16);

  // Get top sellers based on sales count and rating
  const { data: topSellers } = await supabase
    .from('profiles')
    .select(`
      id,
      username,
      avatar_url,
      seller_rating,
      seller_rating_count,
      total_sales,
      followers_count,
      profile_views,
      verification_badges,
      bio,
      location,
      member_since
    `)
    .not('total_sales', 'is', null)
    .gte('total_sales', 1)
    .gte('seller_rating', 1.0)
    .order('total_sales', { ascending: false })
    .order('seller_rating', { ascending: false })
    .limit(5);

  return {
    categories: categories || [],
    featuredListings: featuredListings || [],
    popularListings: popularListings || [],
    topSellers: topSellers || []
  };
};