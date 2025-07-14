import type { PageServerLoad } from './$types';
import { loadCategoryPage } from '$lib/server/category';

export const load: PageServerLoad = async () => {
  return await loadCategoryPage('bags');
};