<script lang="ts">
	import { goto } from '$app/navigation'
	import { user } from '$lib/stores/auth'
	import CreateListingForm from '$lib/components/listings/CreateListingForm.svelte'
	import { onMount } from 'svelte'
	import * as m from '$lib/paraglide/messages.js'
	
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
	<title>{m.sell_page_title()}</title>
	<meta name="description" content={m.sell_page_description()} />
</svelte:head>

{#if $user}
	<CreateListingForm />
{:else}
	<div class="min-h-screen flex items-center justify-center bg-gray-50">
		<div class="text-center">
			<h2 class="text-xl font-semibold mb-2">{m.sell_login_required()}</h2>
			<p class="text-gray-600">{m.sell_need_account()}</p>
		</div>
	</div>
{/if}