<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { formatCurrency } from '$lib/utils/currency.js';
	import { 
		Heart, Share2, MapPin, Shield, Eye, Star,
		ShoppingBag, Truck, CheckCircle, ChevronLeft,
		ChevronRight, MessageCircle, Home, UserPlus, UserMinus
	} from 'lucide-svelte';
	import type { PageData } from './$types';
	import { cn } from '$lib/utils';
	import { fade, scale } from 'svelte/transition';
	import { user as authUser } from '$lib/stores/auth';
	import { supabase } from '$lib/supabase';
	import { toast } from 'svelte-sonner';
	import * as m from '$lib/paraglide/messages.js';

	let { data }: { data: PageData } = $props();

	let listing = $derived(data.listing);
	let currentUser = $derived(data.user);
	let relatedListings = $derived(data.relatedListings);
	let isFollowing = $state(data.isFollowing || false);

	let currentImageIndex = $state(0);
	let isLiked = $state(false);
	let isInCart = $state(false);

	let isOwner = $derived(currentUser?.id === listing?.seller_id);
	let images = $derived(listing?.images || []);
	let hasMultipleImages = $derived(images.length > 1);
	

	function selectImage(index: number) {
		currentImageIndex = index;
	}

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

	async function handleLike() {
		if (!currentUser) {
			goto('/auth/login');
			return;
		}
		isLiked = !isLiked;
	}

	async function handleAddToCart() {
		if (!currentUser) {
			goto('/auth/login');
			return;
		}
		isInCart = true;
		setTimeout(() => {
			isInCart = false;
		}, 2000);
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

	function getAvatarGradient(username: string): string {
		const colors = [
			'from-blue-500 to-purple-500',
			'from-green-500 to-blue-500',
			'from-orange-500 to-red-500',
			'from-purple-500 to-pink-500',
			'from-yellow-500 to-orange-500',
			'from-pink-500 to-red-500'
		];
		const index = username.charCodeAt(0) % colors.length;
		return colors[index];
	}

	function getConditionBadge(condition: string) {
		switch(condition) {
			case 'new_with_tags':
				return { label: 'New with tags', class: 'bg-gradient-to-r from-orange-500 to-red-500 text-white' };
			case 'like_new':
				return { label: 'Like New', class: 'bg-orange-500 text-white' };
			case 'good':
				return { label: 'Good', class: 'bg-orange-400 text-white' };
			case 'worn':
				return { label: 'Worn', class: 'bg-orange-300 text-white' };
			default:
				return { label: condition, class: 'bg-gray-500 text-white' };
		}
	}

	async function handleFollow() {
		const currentUser = $authUser;
		if (!currentUser || !listing) {
			goto('/login');
			return;
		}
		
		try {
			if (isFollowing) {
				// Unfollow
				await supabase
					.from('user_follows')
					.delete()
					.eq('follower_id', currentUser.id)
					.eq('following_id', listing.seller_id);
				
				isFollowing = false;
				toast.success(m.profile_unfollow_success());
			} else {
				// Follow
				await supabase
					.from('user_follows')
					.insert({
						follower_id: currentUser.id,
						following_id: listing.seller_id
					});
				
				isFollowing = true;
				toast.success(m.profile_follow_success());
			}
		} catch (error) {
			console.error('Follow error:', error);
			toast.error(m.profile_follow_update_error());
		}
	}
</script>

<svelte:head>
	<title>{listing?.title || 'Product'} - Driplo</title>
	<meta name="description" content={listing?.description || 'Check out this item on Driplo'} />
</svelte:head>

{#if listing}
	<!-- Compact Header -->
	<div class="sticky top-0 z-50 bg-white border-b">
		<div class="container mx-auto px-4 py-3 flex items-center justify-between">
			<div class="flex items-center gap-3">
				<button
					onclick={() => window.history.back()}
					class="p-2 -ml-2 rounded-lg hover:bg-gray-100 transition-colors"
				>
					<ChevronLeft class="w-5 h-5" />
				</button>
				<nav aria-label="Breadcrumb" class="flex items-center gap-1 text-sm">
					<a href="/" class="text-gray-500 hover:text-gray-700 transition-colors">
						<Home class="w-4 h-4" />
						<span class="sr-only">Home</span>
					</a>
					<ChevronRight class="w-3 h-3 text-gray-400" />
					{#if listing.category}
						<a href="/category/{listing.category.slug}" class="text-gray-500 hover:text-gray-700 transition-colors truncate max-w-[100px]">
							{listing.category.name}
						</a>
						<ChevronRight class="w-3 h-3 text-gray-400" />
					{/if}
					<span class="text-gray-900 font-medium truncate max-w-[150px]">{listing.title}</span>
				</nav>
			</div>
			<div class="flex items-center gap-2">
				<button
					onclick={handleShare}
					class="p-2 rounded-lg hover:bg-gray-100 transition-colors"
				>
					<Share2 class="w-5 h-5" />
				</button>
			</div>
		</div>
	</div>

	<!-- Main Content -->
	<div class="container mx-auto px-4 py-4 lg:py-6 pb-24">
		<div class="lg:grid lg:grid-cols-2 lg:gap-6 xl:gap-8 max-w-6xl mx-auto">
			<!-- Left: Image Section -->
			<div class="mb-4 lg:mb-0">

				<!-- Main Image with Border -->
				<div class="relative bg-white rounded-xl shadow-product p-3 mb-3">
					<div class="relative aspect-[3/4] overflow-hidden rounded-lg bg-gray-50">
						<img
							src={images[currentImageIndex]}
							alt="{listing.title} - Image {currentImageIndex + 1}"
							class="w-full h-full object-cover"
							loading="eager"
						/>
						
						<!-- Condition Badge Overlay -->
						{#if listing.condition}
							<div class="absolute top-3 left-3 {getConditionBadge(listing.condition).class} px-2 py-1 rounded-full text-xs font-medium shadow-sm">
								{getConditionBadge(listing.condition).label}
							</div>
						{/if}

						<!-- Navigation Arrows -->
						{#if hasMultipleImages}
							<button
								onclick={prevImage}
								disabled={currentImageIndex === 0}
								class="absolute left-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/90 shadow-sm hover:bg-white transition-all disabled:opacity-50"
							>
								<ChevronLeft class="w-4 h-4" />
							</button>
							<button
								onclick={nextImage}
								disabled={currentImageIndex === images.length - 1}
								class="absolute right-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/90 shadow-sm hover:bg-white transition-all disabled:opacity-50"
							>
								<ChevronRight class="w-4 h-4" />
							</button>
						{/if}
					</div>
				</div>

				<!-- Thumbnail Strip -->
				{#if hasMultipleImages}
					<div class="flex gap-2 overflow-x-auto scrollbar-hide mb-3">
						{#each images as image, i}
							<button
								onclick={() => selectImage(i)}
								class={cn(
									"flex-shrink-0 w-20 h-20 rounded-lg overflow-hidden border-2 transition-all",
									i === currentImageIndex 
										? "border-primary shadow-sm" 
										: "border-transparent opacity-70 hover:opacity-100"
								)}
							>
								<img
									src={image}
									alt="Thumbnail {i + 1}"
									class="w-full h-full object-cover"
									loading="lazy"
								/>
							</button>
						{/each}
					</div>
				{/if}

				<!-- All Product Info in One Container - Mobile Only -->
				<div class="bg-white rounded-2xl shadow-sm p-4 mb-3 lg:hidden">
					<!-- Title & Price Row -->
					<div class="mb-4">
						<div class="flex items-start justify-between gap-3">
							<h1 class="text-lg font-bold text-gray-900 flex-1">{listing.title}</h1>
							<div class="flex flex-col items-end flex-shrink-0">
								<span class="text-xl font-bold bg-gradient-to-r from-orange-500 to-red-500 bg-clip-text text-transparent">{formatCurrency(listing.price)}</span>
								{#if listing.original_price && listing.original_price > listing.price}
									<div class="flex items-center gap-1 mt-1">
										<span class="text-xs text-gray-500 line-through">{formatCurrency(listing.original_price)}</span>
										<span class="px-1.5 py-0.5 bg-green-100 text-green-700 rounded-full text-xs font-medium">
											-{Math.round((1 - listing.price / listing.original_price) * 100)}%
										</span>
									</div>
								{/if}
							</div>
						</div>
					</div>


					<!-- Description -->
					<div class="mb-4">
						<p class="text-sm text-gray-700 leading-relaxed">{listing.description}</p>
					</div>

					<!-- Additional Details -->
					<div class="mb-4">
						<!-- Color & Material (if available) -->
						{#if listing.color || listing.material}
							<div class="flex items-center gap-4 mb-3">
								{#if listing.color}
									<div class="flex items-center gap-2">
										<span class="text-xs font-medium text-gray-900">Color:</span>
										<span class="text-sm font-semibold text-gray-700">{listing.color}</span>
									</div>
								{/if}
								{#if listing.material}
									<div class="flex items-center gap-2">
										<span class="text-xs font-medium text-gray-900">Material:</span>
										<span class="text-sm font-semibold text-gray-700">{listing.material}</span>
									</div>
								{/if}
							</div>
						{/if}
						
						<!-- Shipping Badge -->
						<div class="inline-flex items-center gap-1.5 bg-green-50 text-green-700 px-3 py-1.5 rounded-full text-xs font-medium mb-3">
							<Truck class="w-3.5 h-3.5" />
							{listing.shipping_price > 0 ? formatCurrency(listing.shipping_price) + ' shipping' : 'FREE shipping'}
						</div>
						
						<!-- Views & Posted -->
						<div class="flex items-center gap-3 text-xs text-gray-500">
							<span class="flex items-center gap-1">
								<Eye class="w-3.5 h-3.5" />
								{listing.view_count || 0} views
							</span>
							<span>•</span>
							<span>Posted 2 days ago</span>
							{#if listing.location}
								<span>•</span>
								<span class="flex items-center gap-1">
									<MapPin class="w-3.5 h-3.5" />
									{listing.location}
								</span>
							{/if}
						</div>
					</div>
					
					<div class="border-t border-gray-100 pt-4">
						<!-- Product Attributes Grid -->
						<div class="grid grid-cols-4 gap-2">
							{#if listing.category}
								<div class="bg-gray-50 rounded-lg p-2.5 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-0.5">Category</p>
									<p class="text-sm font-bold text-orange-600 truncate">{listing.category.name}</p>
								</div>
							{/if}
							{#if listing.brand}
								<div class="bg-gray-50 rounded-lg p-2.5 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-0.5">Brand</p>
									<p class="text-sm font-bold text-orange-600 truncate">{listing.brand}</p>
								</div>
							{/if}
							{#if listing.size}
								<div class="bg-gray-50 rounded-lg p-2.5 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-0.5">Size</p>
									<p class="text-sm font-bold text-orange-600">{listing.size}</p>
								</div>
							{/if}
							{#if listing.color}
								<div class="bg-gray-50 rounded-lg p-2.5 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-0.5">Color</p>
									<p class="text-sm font-bold text-orange-600">{listing.color}</p>
								</div>
							{/if}
						</div>
					</div>
				</div>

				<!-- Seller Info - Mobile Only -->
				<div class="bg-white rounded-2xl shadow-sm p-4 mb-3 lg:hidden">
					<div class="flex items-center justify-between">
						<a href="/profile/{listing.seller.username}" class="flex items-center gap-3">
							{#if listing.seller.avatar_url}
								<img
									src={listing.seller.avatar_url}
									alt={listing.seller.username}
									class="w-12 h-12 rounded-full object-cover"
								/>
							{:else}
								<div class={cn("w-12 h-12 rounded-full bg-gradient-to-br flex items-center justify-center", getAvatarGradient(listing.seller.username))}>
									<span class="text-base font-medium text-white">{listing.seller.username.charAt(0).toUpperCase()}</span>
								</div>
							{/if}
							<div>
								<div class="font-semibold text-base flex items-center gap-1">
									{listing.seller.username}
									{#if listing.seller.verification_badges?.includes('verified')}
										<Shield class="w-4 h-4 text-blue-500" />
									{/if}
								</div>
								<div class="flex items-center gap-2 text-sm text-gray-600">
									<div class="flex items-center gap-0.5">
										<Star class="w-4 h-4 fill-yellow-400 text-yellow-400" />
										<span>{listing.seller.rating || 4.8}</span>
									</div>
									<span>•</span>
									<span>{listing.seller.sales_count || 0} sales</span>
								</div>
							</div>
						</a>
					</div>
					{#if !isOwner}
						<div class="grid grid-cols-2 gap-2 mt-3">
							<button 
								class={cn(
									"py-2.5 rounded-xl text-sm font-medium transition-colors flex items-center justify-center gap-1",
									isFollowing 
										? "bg-gray-100 text-gray-700 hover:bg-gray-200" 
										: "bg-gradient-to-r from-orange-500 to-red-500 text-white hover:from-orange-600 hover:to-red-600"
								)}
								onclick={handleFollow}
							>
								{#if isFollowing}
									<UserMinus class="w-4 h-4" />
									{m.profile_header_following()}
								{:else}
									<UserPlus class="w-4 h-4" />
									{m.profile_header_follow()}
								{/if}
							</button>
							<button class="py-2.5 bg-white border border-orange-300 text-orange-600 rounded-xl text-sm font-medium hover:bg-orange-50 transition-colors flex items-center justify-center gap-2">
								<MessageCircle class="w-4 h-4" />
								Message
							</button>
						</div>
					{/if}
				</div>
			</div>

			<!-- Right: Info Section - Desktop Only -->
			<div class="hidden lg:block lg:sticky lg:top-20 lg:h-fit">
				<!-- All Product Info in One Card -->
				<div class="bg-white rounded-2xl shadow-sm p-6 mb-3">
					<!-- Title & Price Row -->
					<div class="flex items-start justify-between gap-4 mb-6">
						<h1 class="text-2xl font-bold text-gray-900 flex-1">{listing.title}</h1>
						<div class="flex flex-col items-end flex-shrink-0">
							<span class="text-3xl font-bold bg-gradient-to-r from-orange-500 to-red-500 bg-clip-text text-transparent">{formatCurrency(listing.price)}</span>
							{#if listing.original_price && listing.original_price > listing.price}
								<div class="flex items-center gap-2 mt-1">
									<span class="text-sm text-gray-500 line-through">{formatCurrency(listing.original_price)}</span>
									<span class="px-3 py-1 bg-green-100 text-green-700 rounded-full text-sm font-medium">
										-{Math.round((1 - listing.price / listing.original_price) * 100)}%
									</span>
								</div>
							{/if}
						</div>
					</div>

					<!-- Description -->
					<div class="mb-6">
						<p class="text-sm text-gray-700 leading-relaxed">{listing.description}</p>
					</div>

					<!-- Additional Details -->
					<div class="mb-6">
						<!-- Color & Material (if available) -->
						{#if listing.color || listing.material}
							<div class="flex items-center gap-6 mb-4">
								{#if listing.color}
									<div class="flex items-center gap-2">
										<span class="text-sm font-medium text-gray-900">Color:</span>
										<span class="text-sm font-semibold text-gray-700">{listing.color}</span>
									</div>
								{/if}
								{#if listing.material}
									<div class="flex items-center gap-2">
										<span class="text-sm font-medium text-gray-900">Material:</span>
										<span class="text-sm font-semibold text-gray-700">{listing.material}</span>
									</div>
								{/if}
							</div>
						{/if}
						
						<!-- Shipping Badge -->
						<div class="inline-flex items-center gap-1.5 bg-green-50 text-green-700 px-4 py-2 rounded-full text-sm font-medium mb-4">
							<Truck class="w-4 h-4" />
							{listing.shipping_price > 0 ? formatCurrency(listing.shipping_price) + ' shipping' : 'FREE shipping'}
						</div>
						
						<!-- Views & Posted -->
						<div class="flex items-center gap-3 text-sm text-gray-500">
							<span class="flex items-center gap-1">
								<Eye class="w-4 h-4" />
								{listing.view_count || 0} views
							</span>
							<span>•</span>
							<span>Posted 2 days ago</span>
							{#if listing.location}
								<span>•</span>
								<span class="flex items-center gap-1">
									<MapPin class="w-4 h-4" />
									{listing.location}
								</span>
							{/if}
						</div>
					</div>
					
					<div class="border-t border-gray-100 pt-6">
						<!-- Product Attributes Grid -->
						<div class="grid grid-cols-4 gap-3">
							{#if listing.category}
								<div class="bg-gray-50 rounded-lg p-3 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-1">Category</p>
									<p class="text-sm font-bold text-orange-600 truncate">{listing.category.name}</p>
								</div>
							{/if}
							{#if listing.brand}
								<div class="bg-gray-50 rounded-lg p-3 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-1">Brand</p>
									<p class="text-sm font-bold text-orange-600 truncate">{listing.brand}</p>
								</div>
							{/if}
							{#if listing.size}
								<div class="bg-gray-50 rounded-lg p-3 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-1">Size</p>
									<p class="text-sm font-bold text-orange-600">{listing.size}</p>
								</div>
							{/if}
							{#if listing.color}
								<div class="bg-gray-50 rounded-lg p-3 text-center border border-gray-100">
									<p class="text-xs font-medium text-gray-900 mb-1">Color</p>
									<p class="text-sm font-bold text-orange-600">{listing.color}</p>
								</div>
							{/if}
						</div>
					</div>
				</div>

				<!-- Seller Card - Desktop Only -->
				<div class="bg-white rounded-2xl shadow-sm p-5">
					<div class="flex items-center justify-between mb-4">
						<a href="/profile/{listing.seller.username}" class="flex items-center gap-3">
							{#if listing.seller.avatar_url}
								<img
									src={listing.seller.avatar_url}
									alt={listing.seller.username}
									class="w-14 h-14 rounded-full object-cover"
								/>
							{:else}
								<div class={cn("w-14 h-14 rounded-full bg-gradient-to-br flex items-center justify-center", getAvatarGradient(listing.seller.username))}>
									<span class="text-lg font-medium text-white">{listing.seller.username.charAt(0).toUpperCase()}</span>
								</div>
							{/if}
							<div>
								<div class="font-semibold text-lg flex items-center gap-1">
									{listing.seller.username}
									{#if listing.seller.verification_badges?.includes('verified')}
										<Shield class="w-4 h-4 text-blue-500" />
									{/if}
								</div>
								<div class="flex items-center gap-2 text-sm text-gray-600">
									<div class="flex items-center gap-0.5">
										<Star class="w-4 h-4 fill-yellow-400 text-yellow-400" />
										<span>{listing.seller.rating || 4.8}</span>
									</div>
									<span>•</span>
									<span>{listing.seller.sales_count || 0} sales</span>
								</div>
							</div>
						</a>
					</div>
					{#if !isOwner}
						<div class="grid grid-cols-2 gap-3">
							<button 
								class={cn(
									"py-2.5 rounded-xl text-sm font-medium transition-colors flex items-center justify-center gap-1",
									isFollowing 
										? "bg-gray-100 text-gray-700 hover:bg-gray-200" 
										: "bg-gradient-to-r from-orange-500 to-red-500 text-white hover:from-orange-600 hover:to-red-600"
								)}
								onclick={handleFollow}
							>
								{#if isFollowing}
									<UserMinus class="w-4 h-4" />
									{m.profile_header_following()}
								{:else}
									<UserPlus class="w-4 h-4" />
									{m.profile_header_follow()}
								{/if}
							</button>
							<button class="py-2.5 bg-white border border-orange-300 text-orange-600 rounded-xl text-sm font-medium hover:bg-orange-50 transition-colors flex items-center justify-center gap-2">
								<MessageCircle class="w-4 h-4" />
								Message
							</button>
						</div>
					{/if}
				</div>
			</div>
		</div>

		<!-- Fixed Bottom Navbar -->
		<div class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 px-4 py-3 z-50 shadow-lg">
			<div class="max-w-6xl mx-auto flex gap-3">
				{#if !isOwner}
					<button
						onclick={handleLike}
						class={cn(
							"flex-1 py-3 rounded-xl font-semibold transition-all flex items-center justify-center gap-2",
							isLiked 
								? "bg-red-50 text-red-500 border border-red-200" 
								: "bg-white border border-gray-200 text-gray-700 hover:bg-gray-50"
						)}
					>
						<Heart class={cn("w-5 h-5", isLiked && "fill-current")} />
						{isLiked ? 'Saved' : 'Save'}
					</button>
					<button
						onclick={handleAddToCart}
						class="flex-1 bg-gradient-to-r from-orange-500 to-red-500 text-white rounded-xl py-3 font-semibold hover:from-orange-600 hover:to-red-600 transition-all flex items-center justify-center gap-2 shadow-sm"
					>
						<ShoppingBag class="w-5 h-5" />
						Buy Now
					</button>
				{:else}
					<button
						onclick={() => goto(`/listings/${listing.id}/edit`)}
						class="flex-1 bg-gradient-to-r from-orange-500 to-red-500 text-white rounded-xl py-3 font-semibold hover:from-orange-600 hover:to-red-600 transition-colors"
					>
						Edit Listing
					</button>
				{/if}
			</div>
		</div>

		<!-- Related Items -->
		{#if relatedListings?.length > 0}
			<div class="mt-8 max-w-6xl mx-auto">
				<h3 class="text-lg font-semibold mb-4">You might also like</h3>
				<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
					{#each relatedListings.slice(0, 6) as item}
						<a href="/listings/{item.id}" class="group">
							<div class="bg-white rounded-lg shadow-product hover:shadow-product-hover transition-all p-2">
								<div class="aspect-[3/4] bg-gray-100 rounded-lg overflow-hidden mb-2">
									<img
										src={item.images?.[0] || '/placeholder.png'}
										alt={item.title}
										class="w-full h-full object-cover group-hover:scale-105 transition-transform"
										loading="lazy"
									/>
								</div>
								<p class="text-sm font-medium truncate">{item.title}</p>
								<p class="text-sm font-semibold text-orange-600">{formatCurrency(item.price)}</p>
							</div>
						</a>
					{/each}
				</div>
			</div>
		{/if}
	</div>
{:else}
	<div class="min-h-screen flex items-center justify-center">
		<p class="text-gray-500">Listing not found</p>
	</div>
{/if}

<style>
	.scrollbar-hide {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	.scrollbar-hide::-webkit-scrollbar {
		display: none;
	}
</style>