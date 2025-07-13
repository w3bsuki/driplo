<script lang="ts">
	import { goto } from '$app/navigation'
	import { user } from '$lib/stores/auth'
	import CreateListingForm from '$lib/components/listings/CreateListingForm.svelte'
	import { onMount } from 'svelte'
	
	onMount(() => {
		// Check auth on mount only
		const unsubscribe = user.subscribe(currentUser => {
			if (currentUser === null) {
				goto('/auth/login?redirect=/sell')
			}
		})
		
		return unsubscribe
	})
</script>

<svelte:head>
	<title>Sell on Threadly | Create New Listing</title>
	<meta name="description" content="List your items for sale on Threadly marketplace" />
</svelte:head>

{#if $user}
	<CreateListingForm />
{:else}
	<div class="min-h-screen flex items-center justify-center bg-gray-50">
		<div class="text-center">
			<h2 class="text-xl font-semibold mb-2">Please log in to sell</h2>
			<p class="text-gray-600">You need an account to list items</p>
		</div>
	</div>
{/if}