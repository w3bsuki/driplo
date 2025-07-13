<script lang="ts">
	import { page } from '$app/stores'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { Button } from '$lib/components/ui'
	import { supabase } from '$lib/supabase'
	import { 
		CheckCircle, ArrowRight, Package, Share2, Eye, 
		TrendingUp, Camera, DollarSign, Sparkles 
	} from 'lucide-svelte'
	import confetti from 'canvas-confetti'
	
	let listing = $state<any>(null)
	let loading = $state(true)
	
	const listingId = $derived($page.url.searchParams.get('id'))
	
	onMount(async () => {
		// Celebrate with confetti!
		confetti({
			particleCount: 100,
			spread: 70,
			origin: { y: 0.6 }
		})
		
		if (listingId) {
			await loadListing()
		} else {
			loading = false
		}
	})
	
	async function loadListing() {
		try {
			const { data, error } = await supabase
				.from('listings')
				.select('*, seller:profiles(*)')
				.eq('id', listingId)
				.single()
			
			if (error) throw error
			listing = data
		} catch (error) {
			console.error('Error loading listing:', error)
		} finally {
			loading = false
		}
	}
	
	function handleShare() {
		if (navigator.share && listing) {
			navigator.share({
				title: listing.title,
				text: `Check out ${listing.title} on Threadly!`,
				url: `${window.location.origin}/listings/${listing.id}`
			})
		} else {
			// Fallback - copy to clipboard
			navigator.clipboard.writeText(`${window.location.origin}/listings/${listing.id}`)
			alert('Link copied to clipboard!')
		}
	}
	
	const tips = [
		{ icon: Camera, text: "Add high-quality photos from multiple angles" },
		{ icon: DollarSign, text: "Price competitively by researching similar items" },
		{ icon: Sparkles, text: "Write detailed descriptions with measurements" },
		{ icon: TrendingUp, text: "Share your listing on social media for more views" }
	]
</script>

<svelte:head>
	<title>Listing Created Successfully! | Threadly</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-b from-orange-50 to-white">
	<div class="max-w-4xl mx-auto px-4 py-8 md:py-16">
		<!-- Success Header -->
		<div class="text-center mb-12">
			<div class="inline-flex items-center justify-center w-20 h-20 bg-green-100 rounded-full mb-6">
				<CheckCircle class="w-10 h-10 text-green-600" />
			</div>
			
			<h1 class="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
				🎉 Your Listing is Live!
			</h1>
			
			<p class="text-lg text-gray-600 max-w-2xl mx-auto">
				Congratulations! Your item is now available for millions of shoppers to discover.
			</p>
		</div>
		
		<!-- Listing Preview Card -->
		{#if loading}
			<div class="bg-white rounded-2xl shadow-lg p-8 mb-8">
				<div class="animate-pulse">
					<div class="h-64 bg-gray-200 rounded-lg mb-4"></div>
					<div class="h-6 bg-gray-200 rounded w-3/4 mb-2"></div>
					<div class="h-4 bg-gray-200 rounded w-1/2"></div>
				</div>
			</div>
		{:else if listing}
			<div class="bg-white rounded-2xl shadow-lg overflow-hidden mb-8">
				<div class="md:flex">
					<div class="md:w-1/3">
						{#if listing.images?.[0]}
							<img 
								src={listing.images[0]} 
								alt={listing.title}
								class="w-full h-64 md:h-full object-cover"
							/>
						{:else}
							<div class="w-full h-64 bg-gray-100 flex items-center justify-center">
								<Package class="w-16 h-16 text-gray-400" />
							</div>
						{/if}
					</div>
					
					<div class="p-6 md:p-8 md:w-2/3">
						<h2 class="text-2xl font-bold text-gray-900 mb-2">{listing.title}</h2>
						<p class="text-3xl font-bold text-orange-600 mb-4">${listing.price}</p>
						
						{#if listing.description}
							<p class="text-gray-600 mb-6 line-clamp-3">{listing.description}</p>
						{/if}
						
						<div class="flex flex-wrap gap-3">
							<Button 
								class="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
								onclick={() => goto(`/listings/${listing.id}`)}
							>
								<Eye class="w-4 h-4 mr-2" />
								View Listing
							</Button>
							
							<Button 
								variant="outline"
								onclick={handleShare}
							>
								<Share2 class="w-4 h-4 mr-2" />
								Share
							</Button>
							
							<Button 
								variant="outline"
								onclick={() => goto('/sell')}
							>
								<Package class="w-4 h-4 mr-2" />
								Create Another
							</Button>
						</div>
					</div>
				</div>
			</div>
		{/if}
		
		<!-- What's Next Section -->
		<div class="bg-white rounded-2xl shadow-lg p-6 md:p-8 mb-8">
			<h3 class="text-xl font-bold text-gray-900 mb-6">What Happens Next?</h3>
			
			<div class="space-y-4">
				<div class="flex gap-4">
					<div class="flex-shrink-0 w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
						<span class="text-orange-600 font-semibold">1</span>
					</div>
					<div>
						<h4 class="font-semibold text-gray-900">Buyers will discover your item</h4>
						<p class="text-gray-600 text-sm mt-1">
							Your listing appears in search results and category pages immediately
						</p>
					</div>
				</div>
				
				<div class="flex gap-4">
					<div class="flex-shrink-0 w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
						<span class="text-orange-600 font-semibold">2</span>
					</div>
					<div>
						<h4 class="font-semibold text-gray-900">Respond to inquiries quickly</h4>
						<p class="text-gray-600 text-sm mt-1">
							Check your messages regularly - fast responses lead to more sales
						</p>
					</div>
				</div>
				
				<div class="flex gap-4">
					<div class="flex-shrink-0 w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
						<span class="text-orange-600 font-semibold">3</span>
					</div>
					<div>
						<h4 class="font-semibold text-gray-900">Ship promptly after sale</h4>
						<p class="text-gray-600 text-sm mt-1">
							Package items securely and ship within 24 hours for best ratings
						</p>
					</div>
				</div>
			</div>
		</div>
		
		<!-- Pro Tips -->
		<div class="bg-gradient-to-r from-orange-100 to-red-100 rounded-2xl p-6 md:p-8">
			<h3 class="text-xl font-bold text-gray-900 mb-6">
				💡 Pro Tips for Success
			</h3>
			
			<div class="grid md:grid-cols-2 gap-4">
				{#each tips as tip}
					<div class="flex gap-3 items-start">
						<div class="flex-shrink-0">
							<svelte:component this={tip.icon} class="w-5 h-5 text-orange-600" />
						</div>
						<p class="text-sm text-gray-700">{tip.text}</p>
					</div>
				{/each}
			</div>
		</div>
		
		<!-- Quick Actions -->
		<div class="mt-12 text-center">
			<div class="flex flex-col sm:flex-row gap-4 justify-center">
				<Button 
					size="lg"
					class="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
					onclick={() => goto('/profile')}
				>
					View Your Profile
					<ArrowRight class="w-4 h-4 ml-2" />
				</Button>
				
				<Button 
					size="lg"
					variant="outline"
					onclick={() => goto('/')}
				>
					Browse Marketplace
				</Button>
			</div>
		</div>
	</div>
</div>