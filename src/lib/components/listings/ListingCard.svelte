<script lang="ts">
	import { Heart } from 'lucide-svelte';
	import { cn } from '$lib/utils';
	import { Badge } from '$lib/components/ui';
	
	interface Props {
		id: string;
		title: string;
		price: number;
		size?: string;
		brand?: string;
		image: string;
		seller: {
			username: string;
			avatar?: string;
		};
		likes?: number;
		isLiked?: boolean;
		condition?: 'new' | 'good' | 'worn';
		eagerLoading?: boolean; // For first 8 cards in viewport
	}
	
	let { id, title, price, size, brand, image, seller, likes = 0, isLiked = false, condition, eagerLoading = false }: Props = $props();
	
	let liked = $state(isLiked);
	let likeCount = $state(likes);
	let likeLoading = $state(false);
	let imageError = $state(false);
	
	function formatPrice(price: number): string {
		return new Intl.NumberFormat('en-GB', {
			style: 'currency',
			currency: 'GBP',
			minimumFractionDigits: 0,
			maximumFractionDigits: 2
		}).format(price);
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

	async function toggleLike(e: MouseEvent) {
		e.preventDefault();
		if (likeLoading) return;
		
		likeLoading = true;
		
		try {
			// Optimistic update
			const wasLiked = liked;
			liked = !liked;
			likeCount = liked ? likeCount + 1 : likeCount - 1;
			
			// TODO: Add actual API call here
			// await supabase.from('favorites').insert/delete...
			
			// Simulate API delay
			await new Promise(resolve => setTimeout(resolve, 300));
		} catch (error) {
			// Revert on error
			liked = !liked;
			likeCount = liked ? likeCount + 1 : likeCount - 1;
			console.error('Error toggling like:', error);
		} finally {
			likeLoading = false;
		}
	}

	function handleImageError() {
		imageError = true;
	}
</script>

<div class="group relative bg-white rounded-lg shadow-product hover:shadow-product-hover transition-all duration-200 motion-safe:hover:-translate-y-0.5 focus-within:ring-2 focus-within:ring-primary focus-within:ring-offset-2">
	<a href="/listings/{id}" class="block focus:outline-none rounded-lg">
		<div class="relative aspect-[3/4] overflow-hidden rounded-t-lg bg-neutral-100">
			{#if !imageError}
				<img
					src={image}
					alt={title}
					class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
					loading={eagerLoading ? 'eager' : 'lazy'}
					decoding="async"
					onerror={handleImageError}
				/>
			{:else}
				<div class="h-full w-full bg-gradient-to-br from-neutral-200 to-neutral-300 flex items-center justify-center">
					<div class="text-neutral-500 text-4xl">📦</div>
				</div>
			{/if}
			<button
				onclick={toggleLike}
				class={cn(
					"absolute top-2 right-2 p-2 rounded-full bg-white/95 backdrop-blur-sm shadow-sm transition-all hover:bg-white hover:shadow-md focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
					likeLoading && "opacity-50 cursor-not-allowed"
				)}
				aria-label={liked ? 'Unlike' : 'Like'}
				disabled={likeLoading}
			>
				<Heart class={cn("h-4 w-4 transition-colors", liked ? "fill-destructive text-destructive" : "text-neutral-600")} />
			</button>
			{#if condition}
				<div class="absolute top-2 left-2">
					<Badge 
						variant="outline"
						class={cn(
							"font-medium shadow-sm border",
							condition === 'new' && "!bg-blue-500 !text-white !border-blue-500 hover:!bg-blue-600",
							condition === 'good' && "!bg-amber-500 !text-white !border-amber-500 hover:!bg-amber-600",
							condition === 'worn' && "!bg-red-500 !text-white !border-red-500 hover:!bg-red-600"
						)}
					>
						{#snippet children()}
							{condition === 'new' ? 'New' : condition === 'good' ? 'Good' : 'Worn'}
						{/snippet}
					</Badge>
				</div>
			{/if}
		</div>
		
		<div class="p-3 space-y-1">
			<div class="flex items-start justify-between gap-2">
				<div class="flex-1 min-w-0">
					<p class="text-sm font-medium text-neutral-900 truncate">{title}</p>
					{#if brand}
						<p class="text-xs text-neutral-500">{brand}</p>
					{/if}
				</div>
				<p class="text-sm font-semibold text-primary">{formatPrice(price)}</p>
			</div>
			
			{#if size}
				<p class="text-xs text-neutral-500">Size {size}</p>
			{/if}
			
			<div class="flex items-center gap-2 pt-1">
				{#if seller.avatar}
					<img
						src={seller.avatar}
						alt={seller.username}
						class="h-5 w-5 rounded-full object-cover"
					/>
				{:else}
					<div class="h-5 w-5 rounded-full bg-gradient-to-br {getAvatarGradient(seller.username)} flex items-center justify-center">
						<span class="text-[10px] font-medium text-white">{seller.username.charAt(0).toUpperCase()}</span>
					</div>
				{/if}
				<span class="text-xs text-neutral-600">{seller.username}</span>
				{#if likeCount > 0}
					<span class="text-xs text-neutral-400 ml-auto" aria-live="polite">{likeCount} {likeCount === 1 ? 'like' : 'likes'}</span>
				{/if}
			</div>
		</div>
	</a>
</div>