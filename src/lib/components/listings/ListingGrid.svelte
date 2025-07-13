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
			condition?: 'new' | 'good' | 'worn';
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
			isLiked: false,
			condition: 'good'
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
			isLiked: true,
			condition: 'new'
		},
		{
			id: '3',
			title: 'Zara Floral Dress',
			price: 25.00,
			size: 'S',
			brand: 'Zara',
			image: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&h=600&fit=crop',
			seller: { username: 'fashionista' },
			likes: 12,
			condition: 'worn'
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
			isLiked: false,
			condition: 'good'
		},
		{
			id: '5',
			title: 'Adidas Originals Hoodie',
			price: 35.00,
			size: 'XL',
			brand: 'Adidas',
			image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&h=600&fit=crop',
			seller: { username: 'streetwear_plug' },
			likes: 18,
			condition: 'new'
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
			isLiked: true,
			condition: 'new'
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
		},
		{
			id: '9',
			title: 'Prada Sunglasses',
			price: 180.00,
			brand: 'Prada',
			image: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400&h=600&fit=crop',
			seller: { username: 'luxury_acc', avatar: 'https://i.pravatar.cc/150?img=6' },
			likes: 67
		},
		{
			id: '10',
			title: 'Champion Sweatshirt',
			price: 28.00,
			size: 'L',
			brand: 'Champion',
			image: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=600&fit=crop',
			seller: { username: 'casual_wear' },
			likes: 11
		},
		{
			id: '11',
			title: 'Gucci Belt',
			price: 420.00,
			brand: 'Gucci',
			image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=600&fit=crop',
			seller: { username: 'designer_deals', avatar: 'https://i.pravatar.cc/150?img=7' },
			likes: 156,
			isLiked: false,
			condition: 'new'
		},
		{
			id: '12',
			title: 'Uniqlo Basic Tee',
			price: 8.00,
			size: 'M',
			brand: 'Uniqlo',
			image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=600&fit=crop',
			seller: { username: 'basics_lover' },
			likes: 3
		},
		{
			id: '13',
			title: 'Coach Crossbody Bag',
			price: 95.00,
			brand: 'Coach',
			image: 'https://images.unsplash.com/photo-1566150905458-1bf1fc92eddc?w=400&h=600&fit=crop',
			seller: { username: 'bag_collector', avatar: 'https://i.pravatar.cc/150?img=8' },
			likes: 42
		},
		{
			id: '14',
			title: 'Vans Old Skool',
			price: 55.00,
			size: 'UK 8',
			brand: 'Vans',
			image: 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=400&h=600&fit=crop',
			seller: { username: 'skate_shop' },
			likes: 29,
			isLiked: true
		},
		{
			id: '15',
			title: 'Mango Wool Coat',
			price: 75.00,
			size: 'S',
			brand: 'Mango',
			image: 'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=400&h=600&fit=crop',
			seller: { username: 'coat_collector' },
			likes: 19,
			condition: 'good'
		},
		{
			id: '16',
			title: 'Ray-Ban Aviators',
			price: 110.00,
			brand: 'Ray-Ban',
			image: 'https://images.unsplash.com/photo-1508296695146-257a814070b4?w=400&h=600&fit=crop',
			seller: { username: 'eyewear_hub', avatar: 'https://i.pravatar.cc/150?img=9' },
			likes: 38
		},
		{
			id: '17',
			title: 'ASOS Mini Skirt',
			price: 15.00,
			size: 'XS',
			brand: 'ASOS',
			image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=600&fit=crop',
			seller: { username: 'trendy_teen' },
			likes: 8
		},
		{
			id: '18',
			title: 'Converse Chuck 70',
			price: 65.00,
			size: 'UK 7',
			brand: 'Converse',
			image: 'https://images.unsplash.com/photo-1605348532760-6753d2c43329?w=400&h=600&fit=crop',
			seller: { username: 'sneaker_vault', avatar: 'https://i.pravatar.cc/150?img=10' },
			likes: 51
		}
	];
</script>

<section class="py-3 md:py-4">
	<div class="container px-4">
		{#if title}
			<h2 class="mb-2 text-base md:text-lg font-semibold text-gray-900">{title}</h2>
		{/if}
		<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-3 md:gap-4">
			{#each mockListings as listing}
				<ListingCard {...listing} />
			{/each}
		</div>
	</div>
</section>