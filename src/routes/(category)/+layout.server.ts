import type { LayoutServerLoad } from './$types';
import { supabase } from '$lib/supabase';

export const load: LayoutServerLoad = async () => {
  // Get all main categories for navigation
  const { data: categories } = await supabase
    .from('categories')
    .select('*')
    .is('parent_id', null)
    .eq('is_active', true)
    .order('sort_order')
    .order('name');

  return {
    categories: categories || []
  };
};