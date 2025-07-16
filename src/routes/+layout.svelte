<script>
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import MobileNav from '$lib/components/layout/MobileNav.svelte';
	import { Toaster } from 'svelte-sonner';
	import { initializeAuth } from '$lib/stores/auth';
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import { ParaglideJS } from '@inlang/paraglide-js-adapter-sveltekit'
	import { i18n } from '$lib/i18n.js'
	import { page } from '$app/stores';

	export let data;

	// Initialize auth store with server-side data
	$: initializeAuth(data.user, data.session);
	
	// Hide mobile nav on product pages
	$: isProductPage = $page.url.pathname.startsWith('/listings/');

	onMount(() => {
		// Listen for auth changes and invalidate data
		const { data: authListener } = data.supabase.auth.onAuthStateChange((event, session) => {
			if (event === 'SIGNED_IN' || event === 'SIGNED_OUT') {
				invalidate('supabase:auth');
			}
		});

		return () => {
			authListener.subscription.unsubscribe();
		};
	});
</script>

<ParaglideJS {i18n}>
	<div class="min-h-screen bg-background">
		<Header categories={data.categories} />
		<main class={isProductPage ? "pb-20 md:pb-0" : "pb-16 md:pb-0"}>
			<slot />
		</main>
		{#if !isProductPage}
			<MobileNav categories={data.categories} />
		{/if}
	</div>

	<Toaster richColors position="top-center" />
</ParaglideJS>

