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

	// Category styling mapping
	const categoryStyles: Record<string, { icon: string; color: string; bgColor: string }> = {
		women: {
			icon: '👗',
			color: 'from-pink-400 to-purple-400',
			bgColor: 'bg-gradient-to-br from-pink-100 to-purple-100'
		},
		men: {
			icon: '👔',
			color: 'from-blue-400 to-indigo-400',
			bgColor: 'bg-gradient-to-br from-blue-100 to-indigo-100'
		},
		kids: {
			icon: '🧸',
			color: 'from-green-400 to-teal-400',
			bgColor: 'bg-gradient-to-br from-green-100 to-teal-100'
		},
		designer: {
			icon: '💎',
			color: 'from-yellow-400 to-orange-400',
			bgColor: 'bg-gradient-to-br from-yellow-100 to-orange-100'
		},
		shoes: {
			icon: '👟',
			color: 'from-red-400 to-pink-400',
			bgColor: 'bg-gradient-to-br from-red-100 to-pink-100'
		},
		bags: {
			icon: '👜',
			color: 'from-purple-400 to-pink-400',
			bgColor: 'bg-gradient-to-br from-purple-100 to-pink-100'
		}
	};

	const mainCategories = $derived([
		{
			name: 'All',
			value: '',
			slug: '',
			icon: '🔍',
			count: 'Browse all',
			color: 'from-orange-400 to-pink-400',
			bgColor: 'bg-gradient-to-br from-orange-100 to-pink-100'
		},
		...categories.map(cat => ({
			name: cat.name,
			value: cat.slug,
			slug: cat.slug,
			icon: categoryStyles[cat.slug]?.icon || '📦',
			count: `${cat.product_count?.[0]?.count || 0} items`,
			color: categoryStyles[cat.slug]?.color || 'from-gray-400 to-gray-600',
			bgColor: categoryStyles[cat.slug]?.bgColor || 'bg-gradient-to-br from-gray-100 to-gray-200'
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

<section class="pt-2 md:pt-3 pb-6 md:pb-8">
	<div class="container px-4">
		<!-- Main Categories with Icon Circles -->
		<div class="mb-2">
			<div class="flex items-start gap-4 md:gap-6 overflow-x-auto pb-4 scrollbar-hide snap-x snap-mandatory justify-start md:justify-center">
				{#each mainCategories as category}
					<button
						onclick={() => selectCategory(category.value)}
						onmouseenter={() => hoveredCategory = category.value}
						onmouseleave={() => hoveredCategory = ''}
						class="group flex-shrink-0 text-center transition-all duration-300 snap-center rounded-xl p-3"
						style="outline: none !important; -webkit-tap-highlight-color: transparent !important; box-shadow: none !important;"
					>
						<!-- Category Icon Container -->
						<div class="relative mb-3 md:mb-4">
							<!-- Icon Circle -->
							<div class={cn(
								"relative w-18 h-18 md:w-28 md:h-28 mx-auto rounded-full transition-all duration-300 border-3 flex items-center justify-center",
								category.bgColor,
								selectedCategory === category.value 
									? "border-orange-500 shadow-lg scale-105 ring-2 ring-orange-200" 
									: hoveredCategory === category.value
										? "border-orange-300 shadow-lg scale-110 ring-1 ring-orange-100"
										: "border-white shadow-md hover:shadow-lg hover:scale-105"
							)}>
								<!-- Emoji Icon -->
								<span class={cn(
									"text-2xl md:text-4xl transition-transform duration-300 select-none",
									hoveredCategory === category.value && "scale-110"
								)}>
									{category.icon}
								</span>
								
								<!-- Glow effect on hover -->
								<div class={cn(
									"absolute inset-0 rounded-full bg-gradient-to-t",
									category.color,
									"opacity-0 transition-opacity duration-300",
									hoveredCategory === category.value ? "opacity-20" : "opacity-0"
								)}></div>
							</div>
						</div>
						
						<!-- Category Info -->
						<div class="min-w-[72px] md:min-w-[112px]">
							<h3 class={cn(
								"text-sm md:text-base font-semibold transition-colors duration-200 mb-1",
								selectedCategory === category.value 
									? "text-orange-600" 
									: hoveredCategory === category.value
										? "text-orange-500"
										: "text-gray-900"
							)}>{category.name}</h3>
							<p class={cn(
								"text-xs md:text-sm font-medium transition-colors duration-200",
								hoveredCategory === category.value ? "text-gray-600" : "text-gray-500"
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