<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { formatCurrency } from '$lib/utils/format';
	import { ChevronLeft, ChevronRight, X, Heart, MessageCircle, Share2, MapPin, Shield, Eye, MoreVertical } from 'lucide-svelte';
	import { clickOutside } from '$lib/utils/clickOutside';
	import type { PageData } from './$types';
	import { cn } from '$lib/utils/cn';

	export let data: PageData;

	$: listing = data.listing;
	$: currentUser = data.user;
	$: relatedListings = data.relatedListings;

	let currentImageIndex = 0;
	let showFullscreen = false;
	let moreMenuOpen = false;
	let currentImagePosition = 0;

	$: isOwner = currentUser?.id === listing?.seller_id;
	$: images = listing?.images || [];
	$: hasMultipleImages = images.length > 1;

	function nextImage() {
		if (currentImageIndex < images.length - 1) {
			currentImageIndex++;
		}
	}

	function prevImage() {
		if (currentImageIndex > 0) {
			currentImageIndex--;
		}
	}

	function selectImage(index: number) {
		currentImageIndex = index;
	}

	async function handleLike() {
		if (!currentUser) {
			goto('/auth/login');
			return;
		}
		// TODO: Implement like functionality
		console.log('Like listing');
	}

	async function handleMessage() {
		if (!currentUser) {
			goto('/auth/login');
			return;
		}
		// TODO: Implement message functionality
		console.log('Message seller');
	}

	async function handleShare() {
		if (navigator.share) {
			try {
				await navigator.share({
					title: listing?.title,
					text: listing?.description,
					url: window.location.href
				});
			} catch (err) {
				console.log('Error sharing:', err);
			}
		}
	}

	async function handleBuyNow() {
		if (!currentUser) {
			goto('/auth/login');
			return;
		}
		// TODO: Implement buy now functionality
		console.log('Buy now');
	}

	function handleSwipe(e: TouchEvent) {
		const touch = e.touches[0];
		if (!touch) return;

		const startX = touch.clientX;
		const imageContainer = e.currentTarget as HTMLElement;

		function handleMove(e: TouchEvent) {
			const touch = e.touches[0];
			const deltaX = touch.clientX - startX;
			
			if (Math.abs(deltaX) > 50) {
				if (deltaX > 0 && currentImageIndex > 0) {
					prevImage();
				} else if (deltaX < 0 && currentImageIndex < images.length - 1) {
					nextImage();
				}
				imageContainer.removeEventListener('touchmove', handleMove);
			}
		}

		imageContainer.addEventListener('touchmove', handleMove);
		imageContainer.addEventListener('touchend', () => {
			imageContainer.removeEventListener('touchmove', handleMove);
		}, { once: true });
	}

	// Format view count
	function formatViews(count: number): string {
		if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
		if (count >= 1000) return `${(count / 1000).toFixed(1)}K`;
		return count.toString();
	}

	// Simple time ago function
	function timeAgo(date: Date): string {
		const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
		
		if (seconds < 60) return 'just now';
		const minutes = Math.floor(seconds / 60);
		if (minutes < 60) return `${minutes}m ago`;
		const hours = Math.floor(minutes / 60);
		if (hours < 24) return `${hours}h ago`;
		const days = Math.floor(hours / 24);
		if (days < 7) return `${days}d ago`;
		const weeks = Math.floor(days / 7);
		if (weeks < 4) return `${weeks}w ago`;
		const months = Math.floor(days / 30);
		if (months < 12) return `${months}mo ago`;
		const years = Math.floor(days / 365);
		return `${years}y ago`;
	}

	onMount(() => {
		// Increment view count
		// TODO: Implement view count increment
	});
</script>

<svelte:head>
	<title>{listing?.title || 'Product'} - Driplo</title>
	<meta name="description" content={listing?.description || 'Check out this item on Driplo'} />
</svelte:head>

{#if listing}
	<div class="min-h-screen bg-gray-50">
		<!-- Social Media Style Layout -->
		<div class="max-w-4xl mx-auto bg-white">
			<!-- Seller Header - Like Instagram/TikTok -->
			<div class="sticky top-0 z-20 bg-white border-b">
				<div class="flex items-center justify-between p-4">
					<div class="flex items-center gap-3">
						<!-- Back button on mobile -->
						<button
							on:click={() => window.history.back()}
							class="md:hidden -ml-2 p-1.5 rounded-full hover:bg-gray-100"
						>
							<ChevronLeft class="w-5 h-5" />
						</button>
						
						<!-- Seller info -->
						<a href="/users/{listing.seller.username}" class="flex items-center gap-3">
							<img
								src={listing.seller.avatar_url || '/default-avatar.png'}
								alt={listing.seller.username}
								class="w-10 h-10 rounded-full object-cover"
							/>
							<div>
								<div class="flex items-center gap-1.5">
									<span class="font-semibold text-sm">{listing.seller.username}</span>
									{#if listing.seller.verification_badges?.includes('verified')}
										<Shield class="w-4 h-4 text-blue-500" />
									{/if}
								</div>
								<div class="text-xs text-gray-500">
									{timeAgo(new Date(listing.created_at))}
								</div>
							</div>
						</a>

						{#if !isOwner}
							<button
								on:click={() => console.log('Follow')}
								class="ml-auto px-4 py-1.5 bg-black text-white rounded-full text-sm font-medium hover:bg-gray-800 transition-colors"
							>
								Follow
							</button>
						{/if}
					</div>

					<!-- More menu -->
					<div class="relative">
						<button
							on:click={() => moreMenuOpen = !moreMenuOpen}
							class="p-1.5 rounded-full hover:bg-gray-100"
						>
							<MoreVertical class="w-5 h-5" />
						</button>
						
						{#if moreMenuOpen}
							<div
								use:clickOutside
								on:click_outside={() => moreMenuOpen = false}
								class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border py-1"
							>
								<button class="w-full px-4 py-2 text-left hover:bg-gray-50 text-sm">
									Report
								</button>
								{#if isOwner}
									<button class="w-full px-4 py-2 text-left hover:bg-gray-50 text-sm">
										Edit
									</button>
									<button class="w-full px-4 py-2 text-left hover:bg-gray-50 text-sm text-red-600">
										Delete
									</button>
								{/if}
							</div>
						{/if}
					</div>
				</div>
			</div>

			<!-- Product Image - Optimized for Mobile -->
			<div class="relative bg-black">
				<div 
					class="relative aspect-square md:aspect-[4/3] overflow-hidden"
					on:touchstart={handleSwipe}
				>
					<img
						src={images[currentImageIndex]}
						alt="{listing.title} - Image {currentImageIndex + 1}"
						class="w-full h-full object-contain"
					/>

					<!-- Image navigation -->
					{#if hasMultipleImages}
						<!-- Desktop navigation arrows -->
						<button
							on:click={prevImage}
							disabled={currentImageIndex === 0}
							class="hidden md:flex absolute left-4 top-1/2 -translate-y-1/2 p-2 bg-white/80 rounded-full hover:bg-white disabled:opacity-50 disabled:cursor-not-allowed"
						>
							<ChevronLeft class="w-5 h-5" />
						</button>
						
						<button
							on:click={nextImage}
							disabled={currentImageIndex === images.length - 1}
							class="hidden md:flex absolute right-4 top-1/2 -translate-y-1/2 p-2 bg-white/80 rounded-full hover:bg-white disabled:opacity-50 disabled:cursor-not-allowed"
						>
							<ChevronRight class="w-5 h-5" />
						</button>

						<!-- Image indicators -->
						<div class="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-1.5">
							{#each images as _, i}
								<button
									on:click={() => selectImage(i)}
									class={cn(
										"w-1.5 h-1.5 rounded-full transition-all",
										i === currentImageIndex ? "bg-white w-6" : "bg-white/50"
									)}
								/>
							{/each}
						</div>
					{/if}

					<!-- Image counter -->
					{#if hasMultipleImages}
						<div class="absolute top-4 right-4 px-2 py-1 bg-black/50 text-white text-xs rounded-full">
							{currentImageIndex + 1}/{images.length}
						</div>
					{/if}
				</div>

				<!-- Engagement bar - Instagram style -->
				<div class="bg-white border-b">
					<div class="flex items-center justify-between p-4">
						<div class="flex items-center gap-4">
							<button
								on:click={handleLike}
								class="p-2 -m-2 hover:bg-gray-100 rounded-full transition-colors"
							>
								<Heart class="w-6 h-6" />
							</button>
							
							<button
								on:click={handleMessage}
								class="p-2 -m-2 hover:bg-gray-100 rounded-full transition-colors"
							>
								<MessageCircle class="w-6 h-6" />
							</button>
							
							<button
								on:click={handleShare}
								class="p-2 -m-2 hover:bg-gray-100 rounded-full transition-colors"
							>
								<Share2 class="w-6 h-6" />
							</button>
						</div>

						<!-- Price - Always visible -->
						<div class="text-xl font-bold">
							{formatCurrency(listing.price)}
						</div>
					</div>

					<!-- View count and likes -->
					<div class="px-4 pb-3">
						<div class="flex items-center gap-3 text-sm text-gray-600">
							<span class="flex items-center gap-1">
								<Eye class="w-4 h-4" />
								{formatViews(listing.view_count || 0)} views
							</span>
							<span>•</span>
							<span>{listing.likes_count || 0} likes</span>
						</div>
					</div>
				</div>
			</div>

			<!-- Product Details -->
			<div class="p-4 space-y-4">
				<!-- Title and condition -->
				<div>
					<h1 class="text-lg font-semibold">{listing.title}</h1>
					<div class="flex items-center gap-2 mt-1">
						<span class={cn(
							"px-2 py-0.5 rounded-full text-xs font-medium",
							listing.condition === 'new' ? "bg-green-100 text-green-700" :
							listing.condition === 'like_new' ? "bg-blue-100 text-blue-700" :
							listing.condition === 'good' ? "bg-yellow-100 text-yellow-700" :
							"bg-gray-100 text-gray-700"
						)}>
							{listing.condition.replace('_', ' ')}
						</span>
						{#if listing.location}
							<span class="flex items-center gap-1 text-xs text-gray-600">
								<MapPin class="w-3 h-3" />
								{listing.location}
							</span>
						{/if}
					</div>
				</div>

				<!-- Key details in grid -->
				<div class="grid grid-cols-3 gap-3">
					{#if listing.size}
						<div class="text-center p-3 bg-gray-50 rounded-lg">
							<div class="text-xs text-gray-500">Size</div>
							<div class="font-medium">{listing.size}</div>
						</div>
					{/if}
					
					{#if listing.brand}
						<div class="text-center p-3 bg-gray-50 rounded-lg">
							<div class="text-xs text-gray-500">Brand</div>
							<div class="font-medium">{listing.brand}</div>
						</div>
					{/if}
					
					{#if listing.color}
						<div class="text-center p-3 bg-gray-50 rounded-lg">
							<div class="text-xs text-gray-500">Color</div>
							<div class="font-medium">{listing.color}</div>
						</div>
					{/if}
				</div>

				<!-- Description -->
				{#if listing.description}
					<div class="py-3 border-t">
						<h2 class="font-medium mb-2">Description</h2>
						<p class="text-sm text-gray-600 whitespace-pre-wrap">{listing.description}</p>
					</div>
				{/if}

				<!-- Action buttons -->
				<div class="flex gap-3 pt-3">
					{#if !isOwner}
						<button
							on:click={handleBuyNow}
							class="flex-1 bg-black text-white py-3 rounded-lg font-medium hover:bg-gray-800 transition-colors"
						>
							Buy Now
						</button>
						<button
							on:click={handleMessage}
							class="flex-1 bg-gray-100 text-black py-3 rounded-lg font-medium hover:bg-gray-200 transition-colors"
						>
							Message
						</button>
					{:else}
						<button
							on:click={() => goto(`/listings/${listing.id}/edit`)}
							class="flex-1 bg-black text-white py-3 rounded-lg font-medium hover:bg-gray-800 transition-colors"
						>
							Edit Listing
						</button>
					{/if}
				</div>

				<!-- Seller profile section -->
				<div class="py-4 border-t">
					<a href="/users/{listing.seller.username}" class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
						<div class="flex items-center gap-3">
							<img
								src={listing.seller.avatar_url || '/default-avatar.png'}
								alt={listing.seller.username}
								class="w-12 h-12 rounded-full object-cover"
							/>
							<div>
								<div class="font-medium">{listing.seller.full_name || listing.seller.username}</div>
								<div class="text-sm text-gray-500">
									{listing.seller.listings_count || 0} listings • {listing.seller.followers_count || 0} followers
								</div>
							</div>
						</div>
						<ChevronRight class="w-5 h-5 text-gray-400" />
					</a>
				</div>

				<!-- Shipping info -->
				{#if listing.shipping_type}
					<div class="py-4 border-t">
						<h3 class="font-medium mb-2">Shipping</h3>
						<div class="space-y-1 text-sm text-gray-600">
							<p>{listing.shipping_type.replace('_', ' ')}</p>
							{#if listing.shipping_price > 0}
								<p>Shipping cost: {formatCurrency(listing.shipping_price)}</p>
							{:else}
								<p>Free shipping</p>
							{/if}
						</div>
					</div>
				{/if}
			</div>

			<!-- Related items -->
			{#if relatedListings?.length > 0}
				<div class="border-t p-4">
					<h3 class="font-medium mb-3">More from {listing.seller.username}</h3>
					<div class="grid grid-cols-3 gap-2">
						{#each relatedListings.slice(0, 6) as item}
							<a href="/listings/{item.id}" class="aspect-square bg-gray-100 rounded-lg overflow-hidden">
								<img
									src={item.images?.[0] || '/placeholder.png'}
									alt={item.title}
									class="w-full h-full object-cover"
								/>
							</a>
						{/each}
					</div>
				</div>
			{/if}
		</div>
	</div>
{:else}
	<div class="min-h-screen flex items-center justify-center">
		<p class="text-gray-500">Listing not found</p>
	</div>
{/if}

<style>
	/* Ensure images don't get too big on desktop */
	@media (min-width: 768px) {
		.aspect-square {
			max-height: 600px;
		}
	}
</style>