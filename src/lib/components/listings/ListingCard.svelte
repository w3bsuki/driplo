<script lang="ts">
	import { Heart } from 'lucide-svelte';
	import { cn } from '$lib/utils';
	
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
	}
	
	let { id, title, price, size, brand, image, seller, likes = 0, isLiked = false }: Props = $props();
	
	let liked = $state(isLiked);
	let likeCount = $state(likes);
	
	function toggleLike(e: MouseEvent) {
		e.preventDefault();
		liked = !liked;
		likeCount = liked ? likeCount + 1 : likeCount - 1;
	}
</script>

<div class="group relative">
	<a href="/listings/{id}" class="block">
		<div class="relative aspect-[3/4] overflow-hidden rounded-lg bg-muted">
			<img
				src={image}
				alt={title}
				class="h-full w-full object-cover transition-transform group-hover:scale-105"
				loading="lazy"
			/>
			<button
				onclick={toggleLike}
				class="absolute top-2 right-2 p-2 rounded-full bg-white/90 backdrop-blur-sm transition-colors hover:bg-white"
				aria-label={liked ? 'Unlike' : 'Like'}
			>
				<Heart class={cn("h-4 w-4", liked && "fill-red-500 text-red-500")} />
			</button>
		</div>
		
		<div class="mt-3 space-y-1">
			<div class="flex items-start justify-between gap-2">
				<div class="flex-1 min-w-0">
					<p class="text-sm font-medium truncate">{title}</p>
					{#if brand}
						<p class="text-xs text-muted-foreground">{brand}</p>
					{/if}
				</div>
				<p class="text-sm font-semibold">£{price.toFixed(2)}</p>
			</div>
			
			{#if size}
				<p class="text-xs text-muted-foreground">Size {size}</p>
			{/if}
			
			<div class="flex items-center gap-2">
				{#if seller.avatar}
					<img
						src={seller.avatar}
						alt={seller.username}
						class="h-5 w-5 rounded-full"
					/>
				{:else}
					<div class="h-5 w-5 rounded-full bg-muted flex items-center justify-center">
						<span class="text-xs">{seller.username.charAt(0).toUpperCase()}</span>
					</div>
				{/if}
				<span class="text-xs text-muted-foreground">{seller.username}</span>
				{#if likeCount > 0}
					<span class="text-xs text-muted-foreground ml-auto">{likeCount} {likeCount === 1 ? 'like' : 'likes'}</span>
				{/if}
			</div>
		</div>
	</a>
</div>