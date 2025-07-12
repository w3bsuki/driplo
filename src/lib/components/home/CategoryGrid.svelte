<script lang="ts">
	const categories = [
		{
			name: 'Women',
			href: '/browse?category=women',
			image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&h=500&fit=crop',
			count: '2.3M items'
		},
		{
			name: 'Men',
			href: '/browse?category=men',
			image: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=400&h=500&fit=crop',
			count: '1.8M items'
		},
		{
			name: 'Kids',
			href: '/browse?category=kids',
			image: 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=400&h=500&fit=crop',
			count: '982K items'
		},
		{
			name: 'Designer',
			href: '/browse?category=designer',
			image: 'https://images.unsplash.com/photo-1609709295948-17d77cb2a69b?w=400&h=500&fit=crop',
			count: '156K items'
		},
		{
			name: 'Shoes',
			href: '/browse?category=shoes',
			image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=500&fit=crop',
			count: '743K items'
		},
		{
			name: 'Accessories',
			href: '/browse?category=accessories',
			image: 'https://images.unsplash.com/photo-1559563458-527698bf5295?w=400&h=500&fit=crop',
			count: '421K items'
		}
	];
</script>

<section class="py-12 md:py-16">
	<div class="container px-4">
		<h2 class="mb-8 text-2xl font-bold text-center">Shop by category</h2>
		<div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
			{#each categories as category}
				<a 
					href={category.href}
					class="group relative overflow-hidden rounded-lg aspect-[4/5] bg-muted"
				>
					<img
						src={category.image}
						alt={category.name}
						class="absolute inset-0 h-full w-full object-cover transition-transform group-hover:scale-105"
						loading="lazy"
					/>
					<div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
					<div class="absolute bottom-0 left-0 right-0 p-4 text-white">
						<h3 class="font-semibold">{category.name}</h3>
						<p class="text-sm opacity-90">{category.count}</p>
					</div>
				</a>
			{/each}
		</div>
	</div>
</section>