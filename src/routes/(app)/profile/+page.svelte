<script lang="ts">
	import { auth } from '$lib/stores/auth'
	import { goto } from '$app/navigation'
	import { onMount } from 'svelte'

	onMount(() => {
		let redirected = false
		
		const unsubscribeUser = auth.user.subscribe(user => {
			if (redirected) return
			
			const unsubscribeProfile = auth.profile.subscribe(profile => {
				if (redirected) return
				
				const unsubscribeLoading = auth.loading.subscribe(loading => {
					if (redirected) return
					
					if (user && profile?.username) {
						redirected = true
						goto(`/profile/${profile.username}`)
					} else if (!loading && !user) {
						redirected = true  
						goto('/auth/login')
					}
				})
			})
		})
	})
</script>

<!-- Loading state while redirecting -->
<div class="min-h-screen flex items-center justify-center">
	<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500"></div>
</div>