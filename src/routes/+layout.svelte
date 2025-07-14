<script>
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import MobileNav from '$lib/components/layout/MobileNav.svelte';
	import { Toaster } from 'svelte-sonner';
	import { initializeAuth } from '$lib/stores/auth';
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import { getLocale, getTextDirection } from '$lib/i18n.js';
	import { languageTag } from '$lib/paraglide/runtime.js';

	let { data, children } = $props();

	// Initialize auth store with server-side data
	$effect(() => {
		initializeAuth(data.user, data.session);
	});
	
	// Reactive locale and direction - ADVANCED PATTERN
	let locale = $derived(getLocale() || 'en');
	let textDirection = $derived(getTextDirection());

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

<!-- ONE-LINER RTL PATTERN FROM YOUR GUIDE -->
<svelte:head>
	<html lang={locale} dir={textDirection}></html>
</svelte:head>

<div class="min-h-screen bg-background">
	<Header categories={data.categories} />
	<main class="pb-16 md:pb-0">
		{@render children()}
	</main>
	<MobileNav categories={data.categories} />
</div>

<Toaster richColors position="top-center" />

