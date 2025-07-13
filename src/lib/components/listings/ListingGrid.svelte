<script lang="ts">
	import { onMount } from 'svelte'
	import { supabase } from '$lib/supabase'
	import ListingCard from './ListingCard.svelte';
	import type { Database } from '$lib/types/database'
	
	type Listing = Database['public']['Tables']['listings']['Row']
	type Profile = Database['public']['Tables']['profiles']['Row']
	
	interface Props {
		title?: string;
		limit?: number;
		orderBy?: 'created_at' | 'price' | 'view_count';
	}
	
	let { title = 'Popular items', limit = 16, orderBy = 'created_at' }: Props = $props();
	
	let listings = $state<any[]>([])
	let loading = $state(true)
	
	onMount(async () => {
		await loadListings()
	})
	
	async function loadListings() {
		try {
			loading = true
			
			const { data, error } = await supabase
				.from('listings')
				.select(`
					*,
					seller:profiles(username, avatar_url)
				`)
				.eq('status', 'active')
				.order(orderBy, { ascending: false })
				.limit(limit)
			
			if (error) throw error
			
			// Transform data to match ListingCard props
			listings = data?.map(listing => ({
				id: listing.id,
				title: listing.title,
				price: listing.price,
				size: listing.size,
				brand: listing.brand,
				image: listing.images?.[0] || 'https://picsum.photos/400/600?random=' + listing.id,
				seller: {
					username: listing.seller?.username || 'user',
					avatar: listing.seller?.avatar_url
				},
				likes: 0, // We'll add this later
				isLiked: false,
				condition: listing.condition === 'new' ? 'new' : listing.condition === 'good' ? 'good' : 'worn'
			})) || []
			
		} catch (error) {
			console.error('Error loading listings:', error)
			listings = []
		} finally {
			loading = false
		}
	}
</script>

<section class="py-3 md:py-4">
	<div class="container px-4">
		{#if title}
			<h2 class="mb-2 text-base md:text-lg font-semibold text-gray-900">{title}</h2>
		{/if}
		
		{#if loading}
			<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-3 md:gap-4">
				{#each Array(8) as _, i}
					<div class="aspect-[3/4] bg-gray-200 rounded-xl animate-pulse"></div>
				{/each}
			</div>
		{:else if listings.length > 0}
			<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-3 md:gap-4">
				{#each listings as listing}
					<ListingCard {...listing} />
				{/each}
			</div>
		{:else}
			<div class="text-center py-12">
				<div class="text-6xl mb-4">🛍️</div>
				<h3 class="text-lg font-medium text-gray-900 mb-2">No listings yet</h3>
				<p class="text-gray-600 mb-4">Be the first to sell something amazing!</p>
				<a 
					href="/sell" 
					class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white font-medium rounded-lg transition-all"
				>
					Start Selling
				</a>
			</div>
		{/if}
	</div>
</section>