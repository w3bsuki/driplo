<script lang="ts">
	import { page } from '$app/stores'
	import { goto } from '$app/navigation'
	import { user as authUser, auth } from '$lib/stores/auth'
	import { supabase } from '$lib/supabase'
	import ProfileHeader from '$lib/components/profile/ProfileHeader.svelte'
	import ProfileStats from '$lib/components/profile/ProfileStats.svelte'
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte'
	import { RatingStars, Button } from '$lib/components/ui'
	import { Badge } from '$lib/components/ui/badge'
	import { MessageCircle, Calendar, Package, Star, LogOut } from 'lucide-svelte'
	import { toast } from 'svelte-sonner'
	import type { PageData } from './$types'
	
	// Get page data from server
	let { data }: { data: PageData } = $props()
	
	// State from server data
	let profile = $state(data.profile)
	let listings = $state(data.listings)
	let reviews = $state(data.reviews)
	let isFollowing = $state(data.isFollowing)
	let activeTab = $state<'listings' | 'reviews' | 'about'>('listings')
	
	// Get username from URL (derived)
	const username = $derived($page.params.username)
	
	// Check if viewing own profile (derived)
	const isOwnProfile = $derived(data.isOwnProfile)
	
	// async function trackProfileView() {
	// 	const currentUser = $authUser
	// 	if (!profile || !currentUser) return
		
	// 	try {
	// 		// Check if user already viewed this profile today
	// 		const today = new Date().toISOString().split('T')[0]
	// 		const { data: existingView } = await supabase
	// 			.from('profile_views')
	// 			.select('id')
	// 			.eq('profile_id', profile.id)
	// 			.eq('viewer_id', currentUser.id)
	// 			.gte('created_at', `${today}T00:00:00Z`)
	// 			.single()
			
	// 		if (!existingView) {
	// 			await supabase
	// 				.from('profile_views')
	// 				.insert({
	// 					profile_id: profile.id,
	// 					viewer_id: currentUser.id
	// 				})
	// 		}
	// 	} catch (error) {
	// 		// Ignore errors for view tracking
	// 		console.log('View tracking error:', error)
	// 	}
	// }
	
	async function handleFollow() {
		const currentUser = $authUser
		if (!currentUser || !profile) {
			toast.error('Please log in to follow users')
			return
		}
		
		try {
			if (isFollowing) {
				// Unfollow
				await supabase
					.from('user_follows')
					.delete()
					.eq('follower_id', currentUser.id)
					.eq('following_id', profile.id)
				
				toast.success('Unfollowed successfully')
				isFollowing = false
				profile.followers_count -= 1
			} else {
				// Follow
				await supabase
					.from('user_follows')
					.insert({
						follower_id: currentUser.id,
						following_id: profile.id
					})
				
				toast.success('Following successfully')
				isFollowing = true
				profile.followers_count += 1
			}
		} catch (error) {
			console.error('Follow error:', error)
			toast.error('Failed to update follow status')
		}
	}
	
	function handleMessage() {
		if (!$authUser) {
			toast.error('Please log in to send messages')
			return
		}
		// TODO: Implement messaging
		toast.info('Messaging feature coming soon!')
	}
	
	function handleEditProfile() {
		goto('/profile/settings')
	}
	
	async function handleSignOut() {
		try {
			await auth.signOut()
			toast.success('Signed out successfully')
		} catch (error) {
			console.error('Sign out error:', error)
			toast.error('Failed to sign out')
		}
	}
	
	function formatDate(dateString: string): string {
		return new Date(dateString).toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'long',
			day: 'numeric'
		})
	}
</script>

<svelte:head>
	<title>{profile?.full_name || profile?.username || 'Profile'} | Threadly</title>
	<meta name="description" content="{profile?.bio || `${profile?.username}'s profile on Threadly marketplace`}" />
</svelte:head>

{#if profile}
	<div class="min-h-screen bg-gray-50">
		<!-- Profile Header - Full Width on Mobile -->
		<ProfileHeader 
			{profile}
			{isOwnProfile}
			{isFollowing}
			onFollow={handleFollow}
			onMessage={handleMessage}
			onEditProfile={handleEditProfile}
		/>
		
		<!-- Navigation Tabs - Sticky and Mobile Optimized -->
		<div class="sticky top-0 z-20 bg-white border-b border-gray-100 shadow-sm">
			<div class="max-w-4xl mx-auto">
				<nav class="flex" aria-label="Profile tabs">
					<button
						class="flex-1 py-3 px-2 border-b-2 font-medium text-sm transition-all relative
							{activeTab === 'listings' 
								? 'border-orange-500 text-orange-600 bg-orange-50/50' 
								: 'border-transparent text-gray-600'
							}"
						onclick={() => activeTab = 'listings'}
					>
						<span class="block">Listings</span>
						<span class="text-xs font-normal opacity-70">{listings.length}</span>
					</button>
					<button
						class="flex-1 py-3 px-2 border-b-2 font-medium text-sm transition-all relative
							{activeTab === 'reviews' 
								? 'border-orange-500 text-orange-600 bg-orange-50/50' 
								: 'border-transparent text-gray-600'
							}"
						onclick={() => activeTab = 'reviews'}
					>
						<span class="block">Reviews</span>
						<span class="text-xs font-normal opacity-70">{reviews.length}</span>
					</button>
					<button
						class="flex-1 py-3 px-2 border-b-2 font-medium text-sm transition-all relative
							{activeTab === 'about' 
								? 'border-orange-500 text-orange-600 bg-orange-50/50' 
								: 'border-transparent text-gray-600'
							}"
						onclick={() => activeTab = 'about'}
					>
						About
					</button>
				</nav>
			</div>
		</div>
		
		<!-- Tab Content -->
		<div class="max-w-4xl mx-auto">
			<div class="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:gap-6 px-4 py-4 lg:py-6">
				<!-- Main Content - Full Width on Mobile -->
				<div class="lg:col-span-2 order-2 lg:order-1">
					{#if activeTab === 'listings'}
						<!-- Listings Tab -->
						{#if listings.length > 0}
							<div class="bg-white rounded-xl p-4 shadow-sm">
								<ListingGrid listings={listings} title="" />
							</div>
						{:else}
							<div class="bg-white rounded-xl p-8 text-center shadow-sm">
								<div class="text-6xl mb-4">🛍️</div>
								<h3 class="text-lg font-medium text-gray-900 mb-2">No listings yet</h3>
								<p class="text-sm text-gray-600 mb-4">
									{isOwnProfile ? "Start selling by creating your first listing!" : `${profile.username} hasn't listed any items yet.`}
								</p>
								{#if isOwnProfile}
									<Button class="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600">
										<Package class="w-4 h-4 mr-2" />
										Create Listing
									</Button>
								{/if}
							</div>
						{/if}
						
					{:else if activeTab === 'reviews'}
						<!-- Reviews Tab -->
						{#if reviews.length > 0}
							<div class="space-y-3">
								{#each reviews as review}
									<div class="bg-white rounded-xl shadow-sm p-4">
										<div class="flex items-start gap-3">
											<img 
												src={review.rater?.avatar_url || `https://api.dicebear.com/7.x/avataaars/svg?seed=${review.rater?.username}`}
												alt={review.rater?.username}
												class="w-8 h-8 rounded-full flex-shrink-0"
											/>
											<div class="flex-1 min-w-0">
												<div class="flex items-start justify-between gap-2 mb-2">
													<div>
														<h4 class="font-medium text-gray-900 text-sm">
															{review.rater?.full_name || review.rater?.username}
														</h4>
														<div class="flex items-center gap-2 mt-1">
															<RatingStars rating={review.rating} size="sm" />
															<Badge variant="outline" class="text-xs">
																Verified
															</Badge>
														</div>
													</div>
													<time class="text-xs text-gray-500">
														{new Date(review.created_at).toLocaleDateString()}
													</time>
												</div>
												
												{#if review.review_text}
													<p class="text-sm text-gray-700 mb-2 leading-relaxed">{review.review_text}</p>
												{/if}
												
												{#if review.listing}
													<div class="inline-flex items-center gap-1.5 text-xs text-gray-600 bg-gray-50 px-2 py-1 rounded-full">
														<Package class="w-3 h-3" />
														<span class="font-medium truncate">{review.listing.title}</span>
													</div>
												{/if}
											</div>
										</div>
									</div>
								{/each}
							</div>
						{:else}
							<div class="bg-white rounded-xl p-8 text-center shadow-sm">
								<div class="text-6xl mb-4">⭐</div>
								<h3 class="text-lg font-medium text-gray-900 mb-2">No reviews yet</h3>
								<p class="text-sm text-gray-600">
									{isOwnProfile ? "Reviews from buyers will appear here." : `${profile.username} doesn't have any reviews yet.`}
								</p>
							</div>
						{/if}
						
					{:else if activeTab === 'about'}
						<!-- About Tab -->
						<div class="bg-white rounded-xl shadow-sm p-4 md:p-6">
							<h3 class="text-lg font-semibold text-gray-900 mb-4">About {profile.username}</h3>
							
							{#if profile.bio}
								<p class="text-sm text-gray-700 mb-6 leading-relaxed">{profile.bio}</p>
							{:else}
								<p class="text-sm text-gray-500 mb-6 italic">No bio added yet.</p>
							{/if}
							
							<div class="space-y-3">
								<div class="flex justify-between items-center py-3 border-b border-gray-100">
									<span class="text-sm text-gray-600">Member since</span>
									<span class="text-sm font-medium">{formatDate(profile.member_since)}</span>
								</div>
								
								{#if profile.location}
									<div class="flex justify-between items-center py-3 border-b border-gray-100">
										<span class="text-sm text-gray-600">Location</span>
										<span class="text-sm font-medium">{profile.location}</span>
									</div>
								{/if}
								
								<div class="flex justify-between items-center py-3 border-b border-gray-100">
									<span class="text-sm text-gray-600">Response time</span>
									<span class="text-sm font-medium">
										{profile.response_time_hours < 24 ? `${profile.response_time_hours} hours` : 'Within a day'}
									</span>
								</div>
								
								{#if profile.total_sales > 0}
									<div class="flex justify-between items-center py-3 border-b border-gray-100">
										<span class="text-sm text-gray-600">Total sales</span>
										<span class="text-sm font-medium">{profile.total_sales.toLocaleString()}</span>
									</div>
								{/if}
								
								{#if profile.verification_badges?.length > 0}
									<div class="pt-3">
										<h4 class="text-sm font-medium text-gray-900 mb-2">Verifications</h4>
										<div class="flex flex-wrap gap-2">
											{#each profile.verification_badges as badge}
												<div class="inline-flex items-center gap-1.5 bg-blue-50 text-blue-700 px-3 py-1.5 rounded-full text-xs font-medium">
													<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
														<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
													</svg>
													{badge}
												</div>
											{/each}
										</div>
									</div>
								{/if}
							</div>
						</div>
					{/if}
				</div>
				
				<!-- Sidebar - First on Mobile -->
				<div class="order-1 lg:order-2 space-y-4">
					<!-- Stats Component -->
					<ProfileStats {profile} showDetailedStats={false} />
					
					<!-- Quick Actions -->
					{#if !isOwnProfile}
						<div class="bg-white rounded-xl shadow-sm p-4">
							<h3 class="text-base font-semibold text-gray-900 mb-3">Quick Actions</h3>
							<div class="space-y-2">
								<button 
									class="w-full bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white font-medium py-2.5 px-4 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 text-sm"
									onclick={handleMessage}
								>
									<MessageCircle class="w-4 h-4" />
									Send Message
								</button>
								<button 
									class="w-full bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium py-2.5 px-4 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 text-sm"
								>
									<Star class="w-4 h-4" />
									Save Seller
								</button>
							</div>
						</div>
					{:else}
						<div class="bg-white rounded-xl shadow-sm p-4">
							<h3 class="text-base font-semibold text-gray-900 mb-3">Account</h3>
							<div class="space-y-2">
								<button 
									class="w-full bg-red-500 hover:bg-red-600 text-white font-medium py-2.5 px-4 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 text-sm"
									onclick={handleSignOut}
								>
									<LogOut class="w-4 h-4" />
									Sign Out
								</button>
							</div>
						</div>
					{/if}
					
					<!-- Safety Tips -->
					<div class="bg-orange-50 rounded-xl p-4 border border-orange-100">
						<h4 class="text-sm font-semibold text-orange-900 mb-2">Safety Tips</h4>
						<ul class="text-xs text-orange-800 space-y-1">
							<li>• Meet in safe, public locations</li>
							<li>• Check item condition before payment</li>
							<li>• Use secure payment methods</li>
							<li>• Keep communication on platform</li>
						</ul>
					</div>
				</div>
			</div>
		</div>
	</div>
{:else}
	<div class="min-h-screen flex items-center justify-center">
		<div class="text-center">
			<h1 class="text-2xl font-bold text-gray-900 mb-2">Profile not found</h1>
			<p class="text-gray-600 mb-4">The user you're looking for doesn't exist.</p>
			<button 
				class="bg-orange-500 hover:bg-orange-600 text-white font-medium py-2 px-4 rounded-lg transition-colors"
				onclick={() => goto('/')}
			>
				Go Home
			</button>
		</div>
	</div>
{/if}