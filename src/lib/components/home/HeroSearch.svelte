<script lang="ts">
	import { Search, Sparkles, TrendingUp } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	
	let searchQuery = $state('');
	let isFocused = $state(false);
	
	const trendingSearches = [
		'vintage levis',
		'designer bags',
		'nike trainers',
		'zara dress',
		'north face jacket'
	];
	
	const categoryQuickLinks = [
		{ icon: '👗', name: 'Dresses', value: 'dresses' },
		{ icon: '👟', name: 'Trainers', value: 'trainers' },
		{ icon: '👜', name: 'Bags', value: 'bags' },
		{ icon: '🧥', name: 'Jackets', value: 'jackets' }
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
</script>

<section class="relative bg-gradient-to-b from-orange-50 to-white py-3 md:py-4">
	<div class="container px-4">
		<div class="max-w-3xl mx-auto">
			
			<!-- Search Bar -->
			<div class="relative group">
				<div class={cn(
					"absolute inset-0 bg-gradient-to-r from-orange-400 to-orange-600 rounded-2xl blur-xl opacity-20 transition-all duration-300",
					isFocused && "opacity-30 blur-2xl"
				)}></div>
				
				<div class="relative bg-white rounded-2xl shadow-lg border border-gray-100 transition-all duration-300 hover:shadow-xl">
					<div class="flex items-center">
						<div class="pl-6 pr-3">
							<Search class={cn(
								"h-5 w-5 transition-colors duration-200",
								isFocused ? "text-orange-500" : "text-gray-400"
							)} />
						</div>
						
						<input
							type="search"
							placeholder="Search for items, brands, or users..."
							bind:value={searchQuery}
							onfocus={() => isFocused = true}
							onblur={() => isFocused = false}
							onkeydown={(e) => e.key === 'Enter' && handleSearch()}
							class="flex-1 py-3 md:py-3.5 pr-4 text-sm md:text-base placeholder:text-gray-400 focus:outline-none bg-transparent"
						/>
						
						<button
							onclick={handleSearch}
							class="mr-2 px-4 md:px-5 py-2 bg-gradient-to-r from-orange-500 to-orange-600 text-white font-medium rounded-lg text-sm md:text-base hover:from-orange-600 hover:to-orange-700 transition-all duration-200 active:scale-95"
						>
							Search
						</button>
					</div>
					
					<!-- Quick Category Links -->
					<div class="border-t border-gray-100 px-4 py-2 flex items-center gap-3 overflow-x-auto">
						<span class="text-xs text-gray-500 flex-shrink-0 hidden md:block">Quick:</span>
						{#each categoryQuickLinks as category}
							<button
								onclick={() => goToCategory(category.value)}
								class="flex items-center gap-1 px-2.5 py-1 rounded-full bg-gray-50 hover:bg-orange-50 hover:text-orange-600 transition-all duration-200 text-xs font-medium whitespace-nowrap group"
							>
								<span class="text-sm group-hover:scale-110 transition-transform duration-200">{category.icon}</span>
								<span>{category.name}</span>
							</button>
						{/each}
					</div>
				</div>
			</div>
			
			<!-- Trending Searches - Compact -->
			<div class="mt-3 flex items-center justify-center gap-2 flex-wrap text-xs md:text-sm">
				<span class="text-gray-500">Trending:</span>
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