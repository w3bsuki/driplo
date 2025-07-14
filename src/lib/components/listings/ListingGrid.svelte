<script lang="ts">
	import { onMount } from 'svelte'
	import { supabase } from '$lib/supabase'
	import ListingCard from './ListingCard.svelte';
	import InfiniteScroll from '$lib/components/ui/InfiniteScroll.svelte';
	import type { Database } from '$lib/types/database'
	
	type ListingData = {
		id: string;
		title: string;
		price: number;
		size?: string;
		brand?: string;
		images?: string[];
		seller?: {
			username: string;
			avatar_url?: string;
		};
		favorite_count?: number;
		condition?: 'new' | 'good' | 'worn';
		status: string;
		created_at: string;
		view_count?: number;
	};

	interface Props {
		title?: string;
		limit?: number;
		orderBy?: 'created_at' | 'price' | 'view_count';
		listings?: ListingData[]; // Pre-loaded listings from server
		showLoading?: boolean; // Override loading state
		infiniteScroll?: boolean; // Enable infinite scroll
		hasMore?: boolean; // Has more items to load
		onLoadMore?: () => Promise<void> | void; // Load more callback
	}
	
	let { 
		title = 'Popular items', 
		limit = 16, 
		orderBy = 'created_at',
		listings: serverListings = null,
		showLoading = false,
		infiniteScroll = false,
		hasMore = false,
		onLoadMore
	}: Props = $props();
	
	let listings = $state<ListingData[]>([])
	let loading = $state(showLoading)
	
	// If server listings provided, use them; otherwise load client-side
	const shouldLoadClientSide = $derived(!serverListings)
	
	onMount(async () => {
		if (shouldLoadClientSide) {
			await loadListings()
		} else if (serverListings) {
			listings = transformListings(serverListings)
			loading = false
		}
	})
	
	// Watch for changes in server listings
	$effect(() => {
		if (serverListings && !shouldLoadClientSide) {
			listings = transformListings(serverListings)
			loading = false
		}
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
			
			listings = transformListings(data || [])
			
		} catch (error) {
			console.error('Error loading listings:', error)
			listings = []
		} finally {
			loading = false
		}
	}
	
	function transformListings(rawListings: ListingData[]) {
		return rawListings.map(listing => ({
			id: listing.id,
			title: listing.title,
			price: listing.price,
			size: listing.size,
			brand: listing.brand,
			image: listing.images?.[0] || `https://picsum.photos/400/600?random=${listing.id}`,
			seller: {
				username: listing.seller?.username || 'user',
				avatar: listing.seller?.avatar_url
			},
			likes: listing.favorite_count || 0,
			isLiked: false,
			condition: listing.condition
		}))
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
				{#each listings as listing, index}
					<ListingCard {...listing} eagerLoading={index < 8} />
				{/each}
			</div>
			
			{#if infiniteScroll && onLoadMore}
				<InfiniteScroll 
					{hasMore} 
					loading={loading} 
					onLoadMore={onLoadMore}
					class="mt-8"
				/>
			{/if}
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