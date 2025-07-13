<script lang="ts">
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte';
	import HeroSearch from '$lib/components/home/HeroSearch.svelte';
	import LandingCategories from '$lib/components/home/LandingCategories.svelte';
	import QuickFilters from '$lib/components/home/QuickFilters.svelte';
</script>

<HeroSearch />
<LandingCategories />
<QuickFilters />
<ListingGrid title="Recently added" orderBy="created_at" limit={16} />
<ListingGrid title="Most viewed" orderBy="view_count" limit={16} />
