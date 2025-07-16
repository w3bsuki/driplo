<script lang="ts">
	import { ChevronDown, ChevronRight } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import { clickOutside } from '$lib/actions';
	import type { Category } from '$lib/types';
	import * as m from '$lib/paraglide/messages.js';

	interface Props {
		categories?: Category[];
		isOpen?: boolean;
		onToggle?: () => void;
		onClose?: () => void;
		class?: string;
	}

	let { 
		categories = [], 
		isOpen = false, 
		onToggle = () => {}, 
		onClose = () => {},
		class: className = ''
	}: Props = $props();

	let activeMainCategory = $state('');
	let hoveredCategory = $state('');

	// Category hierarchy with subcategories
	const categoryHierarchy = $derived([
		{
			slug: '',
			name: m.category_all(),
			icon: '🔍',
			subcategories: [
				{ name: m.category_browse_all(), slug: 'all', icon: '👀' },
				{ name: m.category_new_arrivals(), slug: 'new', icon: '✨' },
				{ name: m.category_sale_items(), slug: 'sale', icon: '🏷️' }
			]
		},
		{
			slug: 'women',
			name: m.category_women(),
			icon: '👩',
			subcategories: [
				{ name: m.subcategory_dresses(), slug: 'dresses', icon: '👗' },
				{ name: m.women_tops_blouses(), slug: 'tops', icon: '👚' },
				{ name: m.women_skirts(), slug: 'skirts', icon: '👗' },
				{ name: m.women_pants_jeans(), slug: 'pants', icon: '👖' },
				{ name: m.women_jackets_coats(), slug: 'jackets', icon: '🧥' },
				{ name: m.women_shoes(), slug: 'shoes', icon: '👠' },
				{ name: m.women_bags_accessories(), slug: 'bags', icon: '👜' },
				{ name: m.subcategory_jewelry(), slug: 'jewelry', icon: '💍' },
				{ name: m.women_lingerie(), slug: 'lingerie', icon: '👙' },
				{ name: m.women_activewear(), slug: 'activewear', icon: '🏃‍♀️' }
			]
		},
		{
			slug: 'men',
			name: m.category_men(),
			icon: '👨',
			subcategories: [
				{ name: m.men_tshirts(), slug: 'tshirts', icon: '👕' },
				{ name: m.men_shirts(), slug: 'shirts', icon: '👔' },
				{ name: m.men_pants_jeans(), slug: 'pants', icon: '👖' },
				{ name: m.men_jackets_coats(), slug: 'jackets', icon: '🧥' },
				{ name: m.men_hoodies_sweatshirts(), slug: 'hoodies', icon: '👕' },
				{ name: m.men_shoes(), slug: 'shoes', icon: '👞' },
				{ name: m.men_accessories(), slug: 'accessories', icon: '⌚' },
				{ name: m.men_suits_formal(), slug: 'suits', icon: '🤵' },
				{ name: m.men_activewear(), slug: 'activewear', icon: '🏃‍♂️' },
				{ name: m.men_underwear(), slug: 'underwear', icon: '🩲' }
			]
		},
		{
			slug: 'kids',
			name: m.category_kids(),
			icon: '👶',
			subcategories: [
				{ name: m.kids_baby(), slug: 'baby', icon: '👶' },
				{ name: m.kids_girls(), slug: 'girls', icon: '👧' },
				{ name: m.kids_boys(), slug: 'boys', icon: '👦' },
				{ name: m.kids_shoes(), slug: 'shoes', icon: '👟' },
				{ name: m.kids_school_uniforms(), slug: 'school', icon: '🎒' },
				{ name: m.kids_toys_games(), slug: 'toys', icon: '🧸' },
				{ name: m.kids_maternity(), slug: 'maternity', icon: '🤱' }
			]
		},
		{
			slug: 'designer',
			name: m.category_designer(),
			icon: '💎',
			subcategories: [
				{ name: m.designer_luxury_handbags(), slug: 'handbags', icon: '👜' },
				{ name: m.designer_shoes(), slug: 'shoes', icon: '👠' },
				{ name: m.designer_dresses(), slug: 'dresses', icon: '👗' },
				{ name: m.designer_luxury_watches(), slug: 'watches', icon: '⌚' },
				{ name: m.designer_fine_jewelry(), slug: 'jewelry', icon: '💍' },
				{ name: m.designer_sunglasses(), slug: 'sunglasses', icon: '🕶️' },
				{ name: m.designer_vintage_pieces(), slug: 'vintage', icon: '🕰️' }
			]
		},
		{
			slug: 'home',
			name: m.category_home(),
			icon: '🏠',
			subcategories: [
				{ name: m.home_furniture(), slug: 'furniture', icon: '🪑' },
				{ name: m.home_decor(), slug: 'decor', icon: '🖼️' },
				{ name: m.home_kitchen(), slug: 'kitchen', icon: '🍽️' },
				{ name: m.home_bedding(), slug: 'bedding', icon: '🛏️' },
				{ name: m.home_lighting(), slug: 'lighting', icon: '💡' }
			]
		}
	]);

	function handleMainCategoryClick(categorySlug: string) {
		if (categorySlug === activeMainCategory) {
			// If clicking the same category, toggle it
			activeMainCategory = '';
		} else {
			// Set new active category
			activeMainCategory = categorySlug;
		}
	}

	function handleSubcategoryClick(mainCategory: string, subcategory: string) {
		onClose();
		
		if (mainCategory === '' && subcategory === 'all') {
			// Browse all categories
			goto('/browse');
		} else if (mainCategory === '') {
			// Special categories like new, sale
			goto(`/browse?filter=${subcategory}`);
		} else {
			// Navigate to specific category/subcategory
			goto(`/${mainCategory}?subcategory=${subcategory}`);
		}
	}

	function handleCategoryNavigation(categorySlug: string) {
		onClose();
		if (categorySlug) {
			goto(`/${categorySlug}`);
		} else {
			goto('/browse');
		}
	}
</script>

<!-- Category Dropdown -->
{#if isOpen}
	<div 
		class={cn(
			"absolute top-full left-0 mt-2 w-80 md:w-96 bg-white rounded-2xl shadow-xl border border-gray-200 z-[100] overflow-hidden",
			className
		)}
		use:clickOutside={onClose}
	>
		<div class="max-h-[70vh] overflow-y-auto">
			{#each categoryHierarchy as category}
				<div class="border-b border-gray-100 last:border-b-0">
					<!-- Main Category Header -->
					<button
						onclick={() => handleMainCategoryClick(category.slug)}
						onmouseenter={() => hoveredCategory = category.slug}
						onmouseleave={() => hoveredCategory = ''}
						class={cn(
							"w-full flex items-center justify-between px-4 py-3 text-left transition-colors duration-200 hover:bg-orange-50",
							activeMainCategory === category.slug && "bg-orange-50"
						)}
					>
						<div class="flex items-center gap-3">
							<span class="text-lg">{category.icon}</span>
							<div>
								<div class={cn(
									"font-medium text-sm",
									activeMainCategory === category.slug || hoveredCategory === category.slug
										? "text-orange-600"
										: "text-gray-900"
								)}>
									{category.name}
								</div>
								<div class="text-xs text-gray-500">
									{m.category_subcategories_count({ count: category.subcategories.length })}
								</div>
							</div>
						</div>
						
						<div class="flex items-center gap-2">
							<span
								onclick={(e) => {
									e.stopPropagation();
									handleCategoryNavigation(category.slug);
								}}
								class="text-xs text-orange-600 hover:text-orange-700 px-2 py-1 rounded-md hover:bg-orange-100 transition-colors cursor-pointer"
							>
								{m.category_view_all()}
							</span>
							<ChevronRight class={cn(
								"h-4 w-4 transition-transform duration-200",
								activeMainCategory === category.slug && "rotate-90",
								hoveredCategory === category.slug ? "text-orange-600" : "text-gray-400"
							)} />
						</div>
					</button>
					
					<!-- Subcategories -->
					{#if activeMainCategory === category.slug}
						<div class="bg-gray-50 px-4 py-2">
							<div class="grid grid-cols-2 gap-1">
								{#each category.subcategories as subcategory}
									<button
										onclick={() => handleSubcategoryClick(category.slug, subcategory.slug)}
										class="group flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-gray-700 hover:bg-white hover:text-orange-600 transition-all duration-200 hover:shadow-sm"
									>
										<span class="text-sm group-hover:scale-110 transition-transform duration-200">
											{subcategory.icon}
										</span>
										<span class="text-left truncate">{subcategory.name}</span>
									</button>
								{/each}
							</div>
						</div>
					{/if}
				</div>
			{/each}
		</div>
		
		<!-- Footer -->
		<div class="border-t border-gray-200 p-4 bg-gray-50">
			<div class="flex items-center justify-between text-sm">
				<span class="text-gray-600">{m.category_need_help()}</span>
				<button
					onclick={() => {
						onClose();
						goto('/browse');
					}}
					class="text-orange-600 hover:text-orange-700 font-medium"
				>
					{m.category_browse_all_link()}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	/* Custom scrollbar for the dropdown */
	.overflow-y-auto {
		scrollbar-width: thin;
		scrollbar-color: #e5e7eb transparent;
	}
	
	.overflow-y-auto::-webkit-scrollbar {
		width: 6px;
	}
	
	.overflow-y-auto::-webkit-scrollbar-track {
		background: transparent;
	}
	
	.overflow-y-auto::-webkit-scrollbar-thumb {
		background-color: #e5e7eb;
		border-radius: 3px;
	}
	
	.overflow-y-auto::-webkit-scrollbar-thumb:hover {
		background-color: #d1d5db;
	}
</style>