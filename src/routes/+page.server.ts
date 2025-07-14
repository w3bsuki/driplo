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

  return {
    categories: categories || [],
    featuredListings: featuredListings || [],
    popularListings: popularListings || []
  };
};