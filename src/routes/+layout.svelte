<script>
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import MobileNav from '$lib/components/layout/MobileNav.svelte';
	import { Toaster } from 'svelte-sonner';
</script>

<div class="min-h-screen bg-background">
	<Header />
	<main class="pb-16 md:pb-0">
		<slot />
	</main>
	<MobileNav />
</div>

<Toaster richColors position="top-center" />

