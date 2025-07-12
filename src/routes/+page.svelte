<script lang="ts">
	import Hero from '$lib/components/home/Hero.svelte';
	import CategoryGrid from '$lib/components/home/CategoryGrid.svelte';
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte';
	import { Button } from '$lib/components/ui';
</script>

<Hero />
<CategoryGrid />
<ListingGrid title="Popular items" />

<!-- How it works section -->
<section class="py-12 md:py-16 bg-muted/30">
	<div class="container px-4">
		<h2 class="mb-8 text-2xl font-bold text-center">How it works</h2>
		<div class="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
			<div class="text-center">
				<div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
					<span class="text-2xl font-bold text-primary">1</span>
				</div>
				<h3 class="font-semibold mb-2">List for free</h3>
				<p class="text-sm text-muted-foreground">
					Snap a photo, write a description, and set your price. It only takes minutes.
				</p>
			</div>
			<div class="text-center">
				<div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
					<span class="text-2xl font-bold text-primary">2</span>
				</div>
				<h3 class="font-semibold mb-2">Sell it, ship it</h3>
				<p class="text-sm text-muted-foreground">
					Once sold, ship with our prepaid label. We handle the payment securely.
				</p>
			</div>
			<div class="text-center">
				<div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
					<span class="text-2xl font-bold text-primary">3</span>
				</div>
				<h3 class="font-semibold mb-2">Get paid</h3>
				<p class="text-sm text-muted-foreground">
					Money is released to your account once the buyer confirms delivery.
				</p>
			</div>
		</div>
		<div class="text-center mt-8">
			<Button size="lg" onclick={() => window.location.href='/sell'}>
				Start selling now
			</Button>
		</div>
	</div>
</section>

<ListingGrid title="Recently added" />
