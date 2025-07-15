<script lang="ts">
	import { Search, Sparkles, TrendingUp, ChevronDown } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import CategoryDropdown from '$lib/components/shared/CategoryDropdown.svelte';
	import type { Category } from '$lib/types';
	import * as m from '$lib/paraglide/messages.js';
	
	interface Props {
		categories?: Category[];
	}
	
	let { categories = [] }: Props = $props();
	
	let searchQuery = $state('');
	let isFocused = $state(false);
	let isCategoryDropdownOpen = $state(false);
	
	const trendingSearches = [
		m.search_vintage_levis(),
		m.search_designer_bags(),
		m.search_nike_trainers(),
		m.search_zara_dress(),
		m.search_north_face_jacket()
	];
	
	// Top trending categories - these would be dynamic based on analytics
	const trendingCategories = [
		{ icon: '👗', name: m.category_dresses(), value: 'dresses', trending: true },
		{ icon: '👟', name: m.category_trainers(), value: 'trainers', trending: true },
		{ icon: '👜', name: m.category_bags(), value: 'bags', trending: true },
		{ icon: '🧥', name: m.category_jackets(), value: 'jackets', trending: true },
		{ icon: '👠', name: 'Shoes', value: 'shoes', trending: true },
		{ icon: '👕', name: 'T-Shirts', value: 'tshirts', trending: true },
		{ icon: '👖', name: 'Jeans', value: 'jeans', trending: true },
		{ icon: '⌚', name: 'Watches', value: 'watches', trending: true },
		{ icon: '💍', name: 'Jewelry', value: 'jewelry', trending: true },
		{ icon: '🕶️', name: 'Sunglasses', value: 'sunglasses', trending: true }
	];
	
	function handleSearch() {
		if (searchQuery.trim()) {
			const params = new URLSearchParams();
			params.set('q', searchQuery.trim());
			goto(`/browse?${params.toString()}`);
		} else {
			goto('/browse');
		}
	}
	
	function searchTrending(term: string) {
		searchQuery = term;
		handleSearch();
	}
	
	function goToCategory(category: string) {
		goto(`/browse?category=${category}`);
	}
	
	function toggleCategoryDropdown() {
		isCategoryDropdownOpen = !isCategoryDropdownOpen;
	}
	
	function closeCategoryDropdown() {
		isCategoryDropdownOpen = false;
	}
</script>

<section class="relative bg-gradient-to-b from-orange-50 to-white py-3 md:py-4 pb-0">
	<div class="container px-4">
		<div class="max-w-3xl mx-auto">
			
			<!-- Search Bar -->
			<div class="relative group overflow-visible">
				<div class={cn(
					"absolute inset-0 bg-gradient-to-r from-orange-400 to-orange-600 rounded-2xl blur-xl opacity-20 transition-all duration-300",
					isFocused && "opacity-30 blur-2xl"
				)}></div>
				
				<div class="relative bg-white rounded-2xl shadow-lg border border-orange-200 transition-all duration-300 hover:shadow-xl hover:border-orange-300">
					<div class="flex items-center min-w-0">
						<!-- Category Dropdown Button -->
						<div class="relative flex-shrink-0 pl-4 pr-3 z-[101]">
							<button
								data-categories-button
								onclick={toggleCategoryDropdown}
								class={cn(
									"flex items-center gap-1.5 px-3 py-2 rounded-lg transition-all duration-200 font-medium text-sm",
									isCategoryDropdownOpen 
										? "bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-sm hover:from-orange-600 hover:to-orange-700" 
										: "bg-gradient-to-r from-orange-100 to-orange-200 hover:from-orange-200 hover:to-orange-300 border border-orange-300"
								)}
							>
								<span class={cn(
									isCategoryDropdownOpen ? "text-white" : "text-gray-900"
								)}>Categories</span>
								<ChevronDown class={cn(
									"h-4 w-4 transition-transform duration-200",
									isCategoryDropdownOpen && "rotate-180",
									isCategoryDropdownOpen ? "text-white" : "text-gray-900"
								)} />
							</button>
							
							<CategoryDropdown
								{categories}
								isOpen={isCategoryDropdownOpen}
								onToggle={toggleCategoryDropdown}
								onClose={closeCategoryDropdown}
							/>
						</div>
						
						<!-- Divider -->
						<div class="w-px h-6 bg-orange-200 flex-shrink-0"></div>
						
						<!-- Search Input -->
						<div class="flex-1 min-w-0">
							<input
								type="search"
								placeholder={m.browse_search_placeholder()}
								bind:value={searchQuery}
								onfocus={() => isFocused = true}
								onblur={() => isFocused = false}
								onkeydown={(e) => e.key === 'Enter' && handleSearch()}
								class="w-full py-4 md:py-4.5 pl-4 pr-4 text-sm md:text-base placeholder:text-gray-400 focus:outline-none bg-transparent focus:placeholder:text-orange-400"
							/>
						</div>
						
						<!-- Search Button -->
						<div class="flex-shrink-0 pr-3">
							<button
								onclick={handleSearch}
								class="p-2.5 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-all duration-200 active:scale-95 flex items-center justify-center"
								aria-label="Search"
							>
								<Search class="h-4 w-4" />
							</button>
						</div>
					</div>
					
					<!-- Trending Category Links -->
					<div class="border-t border-orange-100 py-3 md:py-2.5 relative overflow-hidden">
						<div class="mx-4 flex items-center gap-2 md:gap-3 overflow-x-auto relative">
							<span class="text-xs text-gray-500 flex-shrink-0 hidden md:block">{m.search_trending()}:</span>
							{#each trendingCategories as category, i}
								<button
									onclick={() => goToCategory(category.value)}
									class="flex items-center gap-1 px-3 md:px-2.5 py-1.5 md:py-1 rounded-full bg-white/80 backdrop-blur-sm shadow-sm text-gray-800 hover:bg-white hover:shadow-md transition-all duration-200 text-xs font-medium whitespace-nowrap group"
								>
									<span class="text-sm">{category.icon}</span>
									<span>{category.name}</span>
								</button>
							{/each}
						</div>
						<!-- Gradient fade on right side for mobile -->
						<div class="absolute right-0 top-0 bottom-0 w-12 bg-gradient-to-l from-white via-white/80 to-transparent pointer-events-none md:hidden flex items-center justify-end pr-2">
							<span class="text-gray-400 text-xs">→</span>
						</div>
					</div>
				</div>
			</div>
			
			<!-- Trending Searches - Compact -->
			<div class="mt-3 flex items-center justify-center gap-2 flex-wrap text-xs md:text-sm">
				<span class="text-gray-500">{m.search_trending()}:</span>
				{#each trendingSearches.slice(0, 3) as term}
					<button
						onclick={() => searchTrending(term)}
						class="text-gray-600 hover:text-orange-600 transition-colors duration-200"
					>
						{term}
					</button>
				{/each}
			</div>
		</div>
	</div>
</section>

<style>
	/* Hide scrollbar for quick categories */
	.overflow-x-auto {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	.overflow-x-auto::-webkit-scrollbar {
		display: none;
	}
</style>