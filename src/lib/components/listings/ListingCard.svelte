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
	}
	
	let { id, title, price, size, brand, image, seller, likes = 0, isLiked = false, condition }: Props = $props();
	
	let liked = $state(isLiked);
	let likeCount = $state(likes);
	
	function toggleLike(e: MouseEvent) {
		e.preventDefault();
		liked = !liked;
		likeCount = liked ? likeCount + 1 : likeCount - 1;
	}
</script>

<div class="group relative bg-white rounded-lg shadow-product hover:shadow-product-hover transition-all duration-200 motion-safe:hover:-translate-y-0.5">
	<a href="/listings/{id}" class="block">
		<div class="relative aspect-[3/4] overflow-hidden rounded-t-lg bg-neutral-100">
			<img
				src={image}
				alt={title}
				class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
				loading="lazy"
			/>
			<button
				onclick={toggleLike}
				class="absolute top-2 right-2 p-2 rounded-full bg-white/95 backdrop-blur-sm shadow-sm transition-all hover:bg-white hover:shadow-md"
				aria-label={liked ? 'Unlike' : 'Like'}
			>
				<Heart class={cn("h-4 w-4 transition-colors", liked ? "fill-destructive text-destructive" : "text-neutral-600")} />
			</button>
			{#if condition}
				<div class="absolute top-2 left-2">
					<Badge 
						variant="outline"
						class={cn(
							"font-medium shadow-sm border",
							condition === 'new' && "!bg-green-500 !text-white !border-green-500 hover:!bg-green-600",
							condition === 'good' && "!bg-yellow-400 !text-neutral-900 !border-yellow-400 hover:!bg-yellow-500",
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
				<p class="text-sm font-semibold text-primary">£{price.toFixed(2)}</p>
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
					<div class="h-5 w-5 rounded-full bg-neutral-200 flex items-center justify-center">
						<span class="text-[10px] font-medium text-neutral-600">{seller.username.charAt(0).toUpperCase()}</span>
					</div>
				{/if}
				<span class="text-xs text-neutral-600">{seller.username}</span>
				{#if likeCount > 0}
					<span class="text-xs text-neutral-400 ml-auto">{likeCount} {likeCount === 1 ? 'like' : 'likes'}</span>
				{/if}
			</div>
		</div>
	</a>
</div>