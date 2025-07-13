import { json } from '@sveltejs/kit'
import type { RequestHandler } from './$types'

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	// Extract filter parameters from URL
	const searchParams = url.searchParams
	const category = searchParams.get('category') || ''
	const subcategory = searchParams.get('subcategory') || ''
	const search = searchParams.get('q') || ''
	const minPrice = searchParams.get('min_price') ? Number(searchParams.get('min_price')) : null
	const maxPrice = searchParams.get('max_price') ? Number(searchParams.get('max_price')) : null
	const sizes = searchParams.get('sizes')?.split(',').filter(Boolean) || []
	const brands = searchParams.get('brands')?.split(',').filter(Boolean) || []
	const conditions = searchParams.get('conditions')?.split(',').filter(Boolean) || []
	const sortBy = searchParams.get('sort') || 'recent'
	const page = Number(searchParams.get('page')) || 1
	const limit = Number(searchParams.get('limit')) || 24

	try {
		// Build the same query as the main browse page
		let query = supabase
			.from('listings')
			.select(`
				id,
				title,
				description,
				price,
				currency,
				brand,
				size,
				condition,
				images,
				location,
				view_count,
				favorite_count,
				is_negotiable,
				shipping_included,
				shipping_cost,
				created_at,
				seller:profiles(
					id,
					username,
					full_name,
					avatar_url,
					is_verified
				),
				category:categories!listings_category_id_fkey(
					id,
					name,
					slug,
					icon_url
				)
			`)
			.eq('status', 'active')

		// Apply category filter
		if (category) {
			const { data: categoryData } = await supabase
				.from('categories')
				.select('id')
				.or(`slug.eq.${category},name.ilike.%${category}%`)
				.single()
			
			if (categoryData) {
				query = query.eq('category_id', categoryData.id)
			}
		}

		// Apply subcategory filter
		if (subcategory) {
			const { data: subcategoryData } = await supabase
				.from('categories')
				.select('id')
				.or(`slug.eq.${subcategory},name.ilike.%${subcategory}%`)
				.single()
			
			if (subcategoryData) {
				query = query.eq('subcategory_id', subcategoryData.id)
			}
		}

		// Apply search filter with full-text search and fallback
		if (search) {
			const searchTerms = search.trim().split(/\s+/).join(' | ')
			query = query.or(`title.fts.${searchTerms},description.fts.${searchTerms},brand.ilike.%${search}%,title.ilike.%${search}%,description.ilike.%${search}%`)
		}

		// Apply price range filters
		if (minPrice !== null) {
			query = query.gte('price', minPrice)
		}
		if (maxPrice !== null) {
			query = query.lte('price', maxPrice)
		}

		// Apply size filters
		if (sizes.length > 0) {
			query = query.in('size', sizes)
		}

		// Apply brand filters
		if (brands.length > 0) {
			query = query.in('brand', brands)
		}

		// Apply condition filters
		if (conditions.length > 0) {
			query = query.in('condition', conditions)
		}

		// Apply sorting
		switch (sortBy) {
			case 'price-low':
				query = query.order('price', { ascending: true })
				break
			case 'price-high':
				query = query.order('price', { ascending: false })
				break
			case 'popular':
				query = query.order('view_count', { ascending: false })
				break
			case 'liked':
				query = query.order('favorite_count', { ascending: false })
				break
			case 'recent':
			default:
				query = query.order('created_at', { ascending: false })
				break
		}

		// Apply pagination
		const offset = (page - 1) * limit
		query = query.range(offset, offset + limit - 1)

		const { data: listings, error: listingsError } = await query

		if (listingsError) {
			console.error('Error fetching more listings:', listingsError)
			return json({ listings: [], hasMore: false }, { status: 500 })
		}

		// Check if there are more items
		const hasMore = listings && listings.length === limit

		return json({
			listings: listings || [],
			hasMore,
			page
		})
	} catch (err) {
		console.error('Load more error:', err)
		return json({ listings: [], hasMore: false }, { status: 500 })
	}
}