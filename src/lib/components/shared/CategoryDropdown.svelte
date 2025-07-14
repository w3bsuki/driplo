<script lang="ts">
	import { ChevronDown, ChevronRight } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import { clickOutside } from '$lib/actions';
	import type { Category } from '$lib/types';

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
			name: 'All Categories',
			icon: '🔍',
			subcategories: [
				{ name: 'Browse All', slug: 'all', icon: '👀' },
				{ name: 'New Arrivals', slug: 'new', icon: '✨' },
				{ name: 'Sale Items', slug: 'sale', icon: '🏷️' }
			]
		},
		{
			slug: 'women',
			name: 'Women',
			icon: '👩',
			subcategories: [
				{ name: 'Dresses', slug: 'dresses', icon: '👗' },
				{ name: 'Tops & Blouses', slug: 'tops', icon: '👚' },
				{ name: 'Skirts', slug: 'skirts', icon: '👗' },
				{ name: 'Pants & Jeans', slug: 'pants', icon: '👖' },
				{ name: 'Jackets & Coats', slug: 'jackets', icon: '🧥' },
				{ name: 'Shoes', slug: 'shoes', icon: '👠' },
				{ name: 'Bags & Accessories', slug: 'bags', icon: '👜' },
				{ name: 'Jewelry', slug: 'jewelry', icon: '💍' },
				{ name: 'Lingerie', slug: 'lingerie', icon: '👙' },
				{ name: 'Activewear', slug: 'activewear', icon: '🏃‍♀️' }
			]
		},
		{
			slug: 'men',
			name: 'Men',
			icon: '👨',
			subcategories: [
				{ name: 'T-Shirts', slug: 'tshirts', icon: '👕' },
				{ name: 'Shirts', slug: 'shirts', icon: '👔' },
				{ name: 'Pants & Jeans', slug: 'pants', icon: '👖' },
				{ name: 'Jackets & Coats', slug: 'jackets', icon: '🧥' },
				{ name: 'Hoodies & Sweatshirts', slug: 'hoodies', icon: '👕' },
				{ name: 'Shoes', slug: 'shoes', icon: '👞' },
				{ name: 'Accessories', slug: 'accessories', icon: '⌚' },
				{ name: 'Suits & Formal', slug: 'suits', icon: '🤵' },
				{ name: 'Activewear', slug: 'activewear', icon: '🏃‍♂️' },
				{ name: 'Underwear', slug: 'underwear', icon: '🩲' }
			]
		},
		{
			slug: 'kids',
			name: 'Kids',
			icon: '👶',
			subcategories: [
				{ name: 'Baby (0-24m)', slug: 'baby', icon: '👶' },
				{ name: 'Girls (2-16y)', slug: 'girls', icon: '👧' },
				{ name: 'Boys (2-16y)', slug: 'boys', icon: '👦' },
				{ name: 'Shoes', slug: 'shoes', icon: '👟' },
				{ name: 'School Uniforms', slug: 'school', icon: '🎒' },
				{ name: 'Toys & Games', slug: 'toys', icon: '🧸' },
				{ name: 'Maternity', slug: 'maternity', icon: '🤱' }
			]
		},
		{
			slug: 'designer',
			name: 'Designer',
			icon: '💎',
			subcategories: [
				{ name: 'Luxury Handbags', slug: 'handbags', icon: '👜' },
				{ name: 'Designer Shoes', slug: 'shoes', icon: '👠' },
				{ name: 'Designer Dresses', slug: 'dresses', icon: '👗' },
				{ name: 'Luxury Watches', slug: 'watches', icon: '⌚' },
				{ name: 'Fine Jewelry', slug: 'jewelry', icon: '💍' },
				{ name: 'Designer Sunglasses', slug: 'sunglasses', icon: '🕶️' },
				{ name: 'Vintage Pieces', slug: 'vintage', icon: '🕰️' }
			]
		},
		{
			slug: 'home',
			name: 'Home & Living',
			icon: '🏠',
			subcategories: [
				{ name: 'Furniture', slug: 'furniture', icon: '🪑' },
				{ name: 'Decor', slug: 'decor', icon: '🖼️' },
				{ name: 'Kitchen', slug: 'kitchen', icon: '🍽️' },
				{ name: 'Bedding', slug: 'bedding', icon: '🛏️' },
				{ name: 'Lighting', slug: 'lighting', icon: '💡' }
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
									{category.subcategories.length} subcategories
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
								View All
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
				<span class="text-gray-600">Need help finding something?</span>
				<button
					onclick={() => {
						onClose();
						goto('/browse');
					}}
					class="text-orange-600 hover:text-orange-700 font-medium"
				>
					Browse All →
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