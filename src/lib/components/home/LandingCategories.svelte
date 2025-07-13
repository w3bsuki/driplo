<script lang="ts">
	import { cn } from '$lib/utils';
	import { goto } from '$app/navigation';
	import { ChevronRight } from 'lucide-svelte';

	let selectedCategory = $state('');
	let hoveredCategory = $state('');

	const mainCategories = [
		{
			name: 'All',
			value: '',
			image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=400&fit=crop',
			count: '5.2M items',
			color: 'from-orange-400 to-pink-400'
		},
		{
			name: 'Women',
			value: 'women',
			image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&h=400&fit=crop',
			count: '2.3M items',
			color: 'from-pink-400 to-purple-400'
		},
		{
			name: 'Men',
			value: 'men',
			image: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=400&h=400&fit=crop',
			count: '1.8M items',
			color: 'from-blue-400 to-indigo-400'
		},
		{
			name: 'Kids',
			value: 'kids',
			image: 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=400&h=400&fit=crop',
			count: '982K items',
			color: 'from-green-400 to-teal-400'
		},
		{
			name: 'Designer',
			value: 'designer',
			image: 'https://images.unsplash.com/photo-1609709295948-17d77cb2a69b?w=400&h=400&fit=crop',
			count: '156K items',
			color: 'from-yellow-400 to-orange-400'
		},
		{
			name: 'Shoes',
			value: 'shoes',
			image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop',
			count: '743K items',
			color: 'from-red-400 to-pink-400'
		},
		{
			name: 'Bags',
			value: 'bags',
			image: 'https://images.unsplash.com/photo-1559563458-527698bf5295?w=400&h=400&fit=crop',
			count: '421K items',
			color: 'from-purple-400 to-pink-400'
		}
	];

	const subcategories = [
		{ name: 'T-shirts', value: 'tshirts', emoji: '👕' },
		{ name: 'Shirts', value: 'shirts', emoji: '👔' },
		{ name: 'Jeans', value: 'jeans', emoji: '👖' },
		{ name: 'Dresses', value: 'dresses', emoji: '👗' },
		{ name: 'Trainers', value: 'trainers', emoji: '👟' },
		{ name: 'Boots', value: 'boots', emoji: '🥾' },
		{ name: 'Jackets', value: 'jackets', emoji: '🧥' },
		{ name: 'Hoodies', value: 'hoodies', emoji: '👕' },
		{ name: 'Handbags', value: 'handbags', emoji: '👜' },
		{ name: 'Watches', value: 'watches', emoji: '⌚' },
		{ name: 'View All', value: 'all', emoji: '→' }
	];

	function selectCategory(category: string) {
		selectedCategory = category;
		const params = new URLSearchParams();
		if (category) {
			params.set('category', category);
		}
		goto(`/browse${params.toString() ? '?' + params.toString() : ''}`);
	}
</script>

<section class="py-3 md:py-4 bg-white">
	<div class="container px-4">
		<!-- Main Categories with Circle Images -->
		<div class="mb-4">
			<div class="flex items-start gap-4 md:gap-6 overflow-x-auto pb-2 scrollbar-hide snap-x snap-mandatory">
				{#each mainCategories as category}
					<button
						onclick={() => selectCategory(category.value)}
						onmouseenter={() => hoveredCategory = category.value}
						onmouseleave={() => hoveredCategory = ''}
						class="group flex-shrink-0 text-center transition-all duration-300 snap-center"
					>
						<!-- Category Image Container -->
						<div class="relative mb-1.5 md:mb-2">
							<!-- Gradient Border on Hover -->
							<div class={cn(
								"absolute inset-0 rounded-full bg-gradient-to-r transition-all duration-300",
								category.color,
								hoveredCategory === category.value || selectedCategory === category.value
									? "opacity-100 blur-sm scale-110" 
									: "opacity-0"
							)}></div>
							
							<!-- Image Circle -->
							<div class={cn(
								"relative w-14 h-14 md:w-20 md:h-20 mx-auto overflow-hidden rounded-full transition-all duration-300 border-2",
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
						<div class="min-w-[56px] md:min-w-[80px]">
							<h3 class={cn(
								"text-xs md:text-sm font-medium transition-colors duration-200",
								selectedCategory === category.value 
									? "text-orange-600" 
									: hoveredCategory === category.value
										? "text-orange-500"
										: "text-gray-900"
							)}>{category.name}</h3>
							<p class={cn(
								"text-[10px] md:text-xs transition-colors duration-200",
								hoveredCategory === category.value ? "text-gray-600" : "text-gray-400"
							)}>{category.count}</p>
						</div>
					</button>
				{/each}
			</div>
		</div>

		<!-- Subcategories Pills -->
		<div>
			<div class="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-hide snap-x">
				{#each subcategories as subcategory}
					<button
						onclick={() => selectCategory(subcategory.value)}
						class={cn(
							"group whitespace-nowrap rounded-full px-3 py-1.5 text-xs md:text-sm font-medium transition-all duration-200 flex-shrink-0 min-h-[32px] md:min-h-[36px] flex items-center gap-1.5 snap-start",
							subcategory.value === 'all'
								? "bg-gradient-to-r from-orange-500 to-orange-600 text-white hover:from-orange-600 hover:to-orange-700 shadow-sm hover:shadow-md"
								: "bg-gray-50 border border-gray-200 hover:border-orange-300 hover:bg-orange-50 text-gray-700 hover:text-orange-600"
						)}
					>
						<span class={cn(
							"text-sm md:text-base transition-transform duration-200 group-hover:scale-110",
							subcategory.value === 'all' && "rotate-0"
						)}>{subcategory.emoji}</span>
						<span>{subcategory.name}</span>
					</button>
				{/each}
			</div>
		</div>
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
</style>