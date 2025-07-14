<script lang="ts">
	import type { PageData } from './$types';
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte';
	import HeroSearch from '$lib/components/home/HeroSearch.svelte';
	import LandingCategories from '$lib/components/home/LandingCategories.svelte';
	import QuickFilters from '$lib/components/home/QuickFilters.svelte';
	
	let { data }: { data: PageData } = $props();
</script>

<HeroSearch categories={data.categories} />
<LandingCategories categories={data.categories} />
<!-- Filters positioned above product cards for better UX -->
<QuickFilters />
<ListingGrid title="" listings={data.featuredListings} showLoading={false} />
<ListingGrid title="Most viewed" listings={data.popularListings} showLoading={false} />
