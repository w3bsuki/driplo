<script>
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import MobileNav from '$lib/components/layout/MobileNav.svelte';
	import { Toaster } from 'svelte-sonner';
	import { initializeAuth } from '$lib/stores/auth';
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';

	export let data;

	// Initialize auth store with server-side data
	$: initializeAuth(data.user, data.session);

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

<div class="min-h-screen bg-background">
	<Header categories={data.categories} />
	<main class="pb-16 md:pb-0">
		<slot />
	</main>
	<MobileNav categories={data.categories} />
</div>

<Toaster richColors position="top-center" />

