<script lang="ts">
	import type { PageData } from './$types';
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte';
	import HeroSearch from '$lib/components/home/HeroSearch.svelte';
	
	let { data }: { data: PageData } = $props();
</script>

<HeroSearch categories={data.categories} />
<ListingGrid title="" listings={data.featuredListings} showLoading={false} />
<ListingGrid title="Most viewed" listings={data.popularListings} showLoading={false} />
