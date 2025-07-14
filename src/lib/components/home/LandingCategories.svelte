<script lang="ts">
	import { cn } from '$lib/utils';
	import { goto } from '$app/navigation';
	import { ChevronRight } from 'lucide-svelte';
	import type { Category } from '$lib/types';

	interface Props {
		categories?: any[];
	}
	
	let { categories = [] }: Props = $props();

	let selectedCategory = $state('');
	let hoveredCategory = $state('');

	// Category images mapping
	const categoryImages: Record<string, { image: string; color: string }> = {
		women: {
			image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&h=400&fit=crop',
			color: 'from-pink-400 to-purple-400'
		},
		men: {
			image: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=400&h=400&fit=crop',
			color: 'from-blue-400 to-indigo-400'
		},
		kids: {
			image: 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=400&h=400&fit=crop',
			color: 'from-green-400 to-teal-400'
		},
		designer: {
			image: 'https://images.unsplash.com/photo-1609709295948-17d77cb2a69b?w=400&h=400&fit=crop',
			color: 'from-yellow-400 to-orange-400'
		},
		shoes: {
			image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop',
			color: 'from-red-400 to-pink-400'
		},
		bags: {
			image: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=400&h=400&fit=crop',
			color: 'from-purple-400 to-pink-400'
		}
	};

	const mainCategories = $derived([
		{
			name: 'All',
			value: '',
			slug: '',
			image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=400&fit=crop',
			count: 'Browse all',
			color: 'from-orange-400 to-pink-400'
		},
		...categories.map(cat => ({
			name: cat.name,
			value: cat.slug,
			slug: cat.slug,
			image: categoryImages[cat.slug]?.image || 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=400&fit=crop',
			count: `${cat.product_count?.[0]?.count || 0} items`,
			color: categoryImages[cat.slug]?.color || 'from-gray-400 to-gray-600'
		}))
	]);

	// Removed subcategories - now handled by CategoryDropdown in HeroSearch

	function selectCategory(categorySlug: string) {
		selectedCategory = categorySlug;
		if (categorySlug) {
			// Navigate to dedicated category page
			goto(`/${categorySlug}`);
		} else {
			// Navigate to browse all
			goto('/browse');
		}
	}

	// Removed selectSubcategory function - subcategories now handled by CategoryDropdown
</script>

<section class="pt-3 md:pt-4 pb-1 md:pb-2 bg-gradient-to-b from-orange-50 to-white">
	<div class="container px-4">
		<!-- Main Categories with Circle Images -->
		<div class="mb-1">
			<div class="flex items-start gap-3 md:gap-5 overflow-x-auto pb-3 scrollbar-hide snap-x snap-mandatory justify-start md:justify-center">
				{#each mainCategories as category}
					<button
						onclick={() => selectCategory(category.value)}
						onmouseenter={() => hoveredCategory = category.value}
						onmouseleave={() => hoveredCategory = ''}
						class="group flex-shrink-0 text-center transition-all duration-300 snap-center rounded-lg p-2"
						style="outline: none !important; -webkit-tap-highlight-color: transparent !important; box-shadow: none !important;"
					>
						<!-- Category Image Container -->
						<div class="relative mb-2 md:mb-3">
							
							<!-- Image Circle -->
							<div class={cn(
								"relative w-16 h-16 md:w-24 md:h-24 mx-auto overflow-hidden rounded-full transition-all duration-300 border-2",
								selectedCategory === category.value 
									? "border-orange-500 shadow-lg scale-105" 
									: hoveredCategory === category.value
										? "border-orange-300 shadow-md scale-105"
										: "border-gray-200 shadow-sm hover:shadow-md"
							)}>
								<img
									src={category.image}
									alt={category.name}
									class={cn(
										"h-full w-full object-cover transition-transform duration-300",
										hoveredCategory === category.value && "scale-110"
									)}
									loading="lazy"
								/>
								
								<!-- Overlay on hover -->
								<div class={cn(
									"absolute inset-0 bg-gradient-to-t from-black/30 to-transparent transition-opacity duration-300",
									hoveredCategory === category.value ? "opacity-100" : "opacity-0"
								)}></div>
							</div>
						</div>
						
						<!-- Category Info -->
						<div class="min-w-[64px] md:min-w-[96px]">
							<h3 class={cn(
								"text-sm md:text-base font-medium transition-colors duration-200 mb-1",
								selectedCategory === category.value 
									? "text-orange-600" 
									: hoveredCategory === category.value
										? "text-orange-500"
										: "text-gray-900"
							)}>{category.name}</h3>
							<p class={cn(
								"text-xs md:text-sm transition-colors duration-200",
								hoveredCategory === category.value ? "text-gray-600" : "text-gray-400"
							)}>{category.count}</p>
						</div>
					</button>
				{/each}
			</div>
		</div>

		<!-- Removed subcategory pills - now handled by CategoryDropdown in HeroSearch -->
	</div>
</section>

<style>
	/* Hide scrollbar for clean mobile experience */
	.scrollbar-hide {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	.scrollbar-hide::-webkit-scrollbar {
		display: none;
	}
	
	/* Remove all browser-specific focus/tap highlights */
	button {
		outline: none !important;
		-webkit-tap-highlight-color: transparent !important;
		-webkit-focus-ring-color: transparent !important;
		-moz-outline: none !important;
		-moz-user-select: none;
		-webkit-user-select: none;
		user-select: none;
		box-shadow: none !important;
	}
	
	button:focus {
		outline: none !important;
		box-shadow: none !important;
		border: none !important;
	}
	
	button:active {
		outline: none !important;
		box-shadow: none !important;
	}
	
	button:focus-visible {
		outline: none !important;
		box-shadow: none !important;
	}
	
	button::-moz-focus-inner {
		border: 0 !important;
		outline: none !important;
	}
</style>