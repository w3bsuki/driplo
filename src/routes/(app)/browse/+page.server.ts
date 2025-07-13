import { error } from '@sveltejs/kit'
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ url, locals: { supabase } }) => {
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
		// Build the base query
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
			// Get category ID by slug/name
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
			// Try full-text search first, then fallback to ILIKE
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
			console.error('Error fetching listings:', listingsError)
			throw error(500, 'Failed to load listings')
		}

		// Get total count for pagination (separate query for performance)
		let countQuery = supabase
			.from('listings')
			.select('id', { count: 'exact', head: true })
			.eq('status', 'active')

		// Apply same filters to count query
		if (category) {
			const { data: categoryData } = await supabase
				.from('categories')
				.select('id')
				.or(`slug.eq.${category},name.ilike.%${category}%`)
				.single()
			
			if (categoryData) {
				countQuery = countQuery.eq('category_id', categoryData.id)
			}
		}

		if (subcategory) {
			const { data: subcategoryData } = await supabase
				.from('categories')
				.select('id')
				.or(`slug.eq.${subcategory},name.ilike.%${subcategory}%`)
				.single()
			
			if (subcategoryData) {
				countQuery = countQuery.eq('subcategory_id', subcategoryData.id)
			}
		}

		if (search) {
			// Apply same search logic to count query
			const searchTerms = search.trim().split(/\s+/).join(' | ')
			countQuery = countQuery.or(`title.fts.${searchTerms},description.fts.${searchTerms},brand.ilike.%${search}%,title.ilike.%${search}%,description.ilike.%${search}%`)
		}

		if (minPrice !== null) {
			countQuery = countQuery.gte('price', minPrice)
		}
		if (maxPrice !== null) {
			countQuery = countQuery.lte('price', maxPrice)
		}

		if (sizes.length > 0) {
			countQuery = countQuery.in('size', sizes)
		}

		if (brands.length > 0) {
			countQuery = countQuery.in('brand', brands)
		}

		if (conditions.length > 0) {
			countQuery = countQuery.in('condition', conditions)
		}

		const { count, error: countError } = await countQuery

		if (countError) {
			console.error('Error fetching count:', countError)
		}

		// Get all categories for filter UI
		const { data: categories, error: categoriesError } = await supabase
			.from('categories')
			.select('id, name, slug, icon_url, parent_id')
			.eq('is_active', true)
			.order('sort_order')

		if (categoriesError) {
			console.error('Error fetching categories:', categoriesError)
		}

		// Get popular brands for filter UI
		const { data: popularBrands, error: brandsError } = await supabase
			.from('listings')
			.select('brand')
			.not('brand', 'is', null)
			.eq('status', 'active')
			.limit(50)

		const brandsList = popularBrands 
			? [...new Set(popularBrands.map(item => item.brand).filter(Boolean))]
				.sort()
				.slice(0, 20)
			: []

		if (brandsError) {
			console.error('Error fetching brands:', brandsError)
		}

		// Calculate pagination info
		const totalPages = count ? Math.ceil(count / limit) : 0
		const hasNextPage = page < totalPages
		const hasPrevPage = page > 1

		return {
			listings: listings || [],
			totalCount: count || 0,
			categories: categories || [],
			popularBrands: brandsList,
			pagination: {
				currentPage: page,
				totalPages,
				hasNextPage,
				hasPrevPage,
				limit
			},
			filters: {
				category,
				subcategory,
				search,
				minPrice,
				maxPrice,
				sizes,
				brands,
				conditions,
				sortBy
			}
		}
	} catch (err) {
		console.error('Browse page error:', err)
		throw error(500, 'Failed to load browse page')
	}
}