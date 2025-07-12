<script lang="ts">
	import ListingCard from './ListingCard.svelte';
	
	interface Props {
		title?: string;
		listings?: Array<{
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
		}>;
	}
	
	let { title = 'Popular items', listings = [] }: Props = $props();
	
	// Mock data for demo
	const mockListings = listings.length > 0 ? listings : [
		{
			id: '1',
			title: 'Vintage Levi\'s Denim Jacket',
			price: 45.00,
			size: 'M',
			brand: 'Levi\'s',
			image: 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=400&h=600&fit=crop',
			seller: { username: 'vintage_finds', avatar: 'https://i.pravatar.cc/150?img=1' },
			likes: 23,
			isLiked: false
		},
		{
			id: '2',
			title: 'Nike Air Max 90',
			price: 85.00,
			size: 'UK 9',
			brand: 'Nike',
			image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=600&fit=crop',
			seller: { username: 'sneakerhead', avatar: 'https://i.pravatar.cc/150?img=2' },
			likes: 45,
			isLiked: true
		},
		{
			id: '3',
			title: 'Zara Floral Dress',
			price: 25.00,
			size: 'S',
			brand: 'Zara',
			image: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&h=600&fit=crop',
			seller: { username: 'fashionista' },
			likes: 12
		},
		{
			id: '4',
			title: 'Burberry Trench Coat',
			price: 350.00,
			size: 'L',
			brand: 'Burberry',
			image: 'https://images.unsplash.com/photo-1559551409-dadc959f76b8?w=400&h=600&fit=crop',
			seller: { username: 'luxury_closet', avatar: 'https://i.pravatar.cc/150?img=3' },
			likes: 89,
			isLiked: false
		},
		{
			id: '5',
			title: 'Adidas Originals Hoodie',
			price: 35.00,
			size: 'XL',
			brand: 'Adidas',
			image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&h=600&fit=crop',
			seller: { username: 'streetwear_plug' },
			likes: 18
		},
		{
			id: '6',
			title: 'Vintage Band T-Shirt',
			price: 30.00,
			size: 'M',
			brand: 'Unknown',
			image: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=600&fit=crop',
			seller: { username: 'retro_threads', avatar: 'https://i.pravatar.cc/150?img=4' },
			likes: 7
		},
		{
			id: '7',
			title: 'Michael Kors Handbag',
			price: 120.00,
			brand: 'Michael Kors',
			image: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&h=600&fit=crop',
			seller: { username: 'bags_boutique' },
			likes: 34,
			isLiked: true
		},
		{
			id: '8',
			title: 'H&M Skinny Jeans',
			price: 20.00,
			size: '32/32',
			brand: 'H&M',
			image: 'https://images.unsplash.com/photo-1542272454315-4c01d7abdf4a?w=400&h=600&fit=crop',
			seller: { username: 'denim_dealer', avatar: 'https://i.pravatar.cc/150?img=5' },
			likes: 5
		}
	];
</script>

<section class="py-8">
	<div class="container px-4">
		{#if title}
			<h2 class="mb-6 text-2xl font-bold">{title}</h2>
		{/if}
		<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 md:gap-6">
			{#each mockListings as listing}
				<ListingCard {...listing} />
			{/each}
		</div>
	</div>
</section>