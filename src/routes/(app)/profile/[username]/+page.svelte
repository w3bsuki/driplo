<script lang="ts">
	import { page } from '$app/stores'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { auth } from '$lib/stores/auth'
	import { supabase } from '$lib/supabase'
	import ProfileHeader from '$lib/components/profile/ProfileHeader.svelte'
	import ProfileStats from '$lib/components/profile/ProfileStats.svelte'
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte'
	import { RatingStars } from '$lib/components/ui'
	import { Badge } from '$lib/components/ui/badge'
	import { MessageCircle, Calendar } from 'lucide-svelte'
	import { toast } from 'svelte-sonner'
	import type { EnhancedUserProfile, UserRating, Listing } from '$lib/types'
	
	// Get username from URL
	$: username = $page.params.username
	
	// State
	let profile = $state<EnhancedUserProfile | null>(null)
	let listings = $state<Listing[]>([])
	let reviews = $state<UserRating[]>([])
	let isFollowing = $state(false)
	let loading = $state(true)
	let activeTab = $state<'listings' | 'reviews' | 'about'>('listings')
	
	// Check if viewing own profile
	$: isOwnProfile = auth.user?.id === profile?.id
	
	onMount(async () => {
		await loadProfile()
	})
	
	async function loadProfile() {
		try {
			loading = true
			
			// Load profile data
			const { data: profileData, error: profileError } = await supabase
				.from('profiles')
				.select(`
					*,
					user_achievements!inner(
						achievement_type,
						level,
						earned_at
					)
				`)
				.eq('username', username)
				.single()
			
			if (profileError) {
				console.error('Error loading profile:', profileError)
				toast.error('Profile not found')
				goto('/')
				return
			}
			
			profile = {
				...profileData,
				achievements: profileData.user_achievements || []
			}
			
			// Load user's listings
			const { data: listingsData } = await supabase
				.from('listings')
				.select('*')
				.eq('seller_id', profile.id)
				.eq('status', 'active')
				.order('created_at', { ascending: false })
				.limit(12)
			
			listings = listingsData || []
			
			// Load reviews
			const { data: reviewsData } = await supabase
				.from('user_ratings')
				.select(`
					*,
					rater:rater_user_id(username, avatar_url, full_name),
					listing:listing_id(title, images)
				`)
				.eq('rated_user_id', profile.id)
				.eq('rating_type', 'seller')
				.order('created_at', { ascending: false })
				.limit(10)
			
			reviews = reviewsData || []
			
			// Check if current user follows this profile
			if (auth.user && !isOwnProfile) {
				const { data: followData } = await supabase
					.from('user_follows')
					.select('id')
					.eq('follower_id', auth.user.id)
					.eq('following_id', profile.id)
					.single()
				
				isFollowing = !!followData
			}
			
			// Track profile view
			if (!isOwnProfile) {
				await trackProfileView()
			}
			
		} catch (error) {
			console.error('Error loading profile:', error)
			toast.error('Failed to load profile')
		} finally {
			loading = false
		}
	}
	
	async function trackProfileView() {
		if (!profile || !auth.user) return
		
		try {
			await supabase
				.from('profile_views')
				.insert({
					profile_id: profile.id,
					viewer_id: auth.user.id
				})
		} catch (error) {
			// Ignore errors for view tracking
			console.log('View tracking error:', error)
		}
	}
	
	async function handleFollow() {
		if (!auth.user || !profile) {
			toast.error('Please log in to follow users')
			return
		}
		
		try {
			if (isFollowing) {
				// Unfollow
				await supabase
					.from('user_follows')
					.delete()
					.eq('follower_id', auth.user.id)
					.eq('following_id', profile.id)
				
				toast.success('Unfollowed successfully')
				isFollowing = false
				profile.followers_count -= 1
			} else {
				// Follow
				await supabase
					.from('user_follows')
					.insert({
						follower_id: auth.user.id,
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
		if (!auth.user) {
			toast.error('Please log in to send messages')
			return
		}
		// TODO: Implement messaging
		toast.info('Messaging feature coming soon!')
	}
	
	function handleEditProfile() {
		goto('/account/settings')
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

{#if loading}
	<div class="min-h-screen flex items-center justify-center">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500"></div>
	</div>
{:else if profile}
	<div class="min-h-screen bg-gray-50">
		<!-- Profile Header -->
		<div class="bg-white shadow-sm">
			<div class="max-w-4xl mx-auto">
				<ProfileHeader 
					{profile}
					{isOwnProfile}
					{isFollowing}
					onFollow={handleFollow}
					onMessage={handleMessage}
					onEditProfile={handleEditProfile}
				/>
			</div>
		</div>
		
		<!-- Navigation Tabs -->
		<div class="max-w-4xl mx-auto px-4 md:px-6">
			<div class="border-b border-gray-200 bg-white">
				<nav class="flex space-x-8" aria-label="Profile tabs">
					<button
						class="py-4 px-1 border-b-2 font-medium text-sm transition-colors
							{activeTab === 'listings' 
								? 'border-orange-500 text-orange-600' 
								: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
							}"
						on:click={() => activeTab = 'listings'}
					>
						Listings ({listings.length})
					</button>
					<button
						class="py-4 px-1 border-b-2 font-medium text-sm transition-colors
							{activeTab === 'reviews' 
								? 'border-orange-500 text-orange-600' 
								: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
							}"
						on:click={() => activeTab = 'reviews'}
					>
						Reviews ({reviews.length})
					</button>
					<button
						class="py-4 px-1 border-b-2 font-medium text-sm transition-colors
							{activeTab === 'about' 
								? 'border-orange-500 text-orange-600' 
								: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
							}"
						on:click={() => activeTab = 'about'}
					>
						About
					</button>
				</nav>
			</div>
		</div>
		
		<!-- Tab Content -->
		<div class="max-w-4xl mx-auto px-4 md:px-6 py-6">
			<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
				<!-- Main Content -->
				<div class="lg:col-span-2">
					{#if activeTab === 'listings'}
						<!-- Listings Tab -->
						{#if listings.length > 0}
							<ListingGrid listings={listings} />
						{:else}
							<div class="text-center py-12">
								<div class="text-gray-400 text-6xl mb-4">📦</div>
								<h3 class="text-lg font-medium text-gray-900 mb-2">No listings yet</h3>
								<p class="text-gray-600">
									{isOwnProfile ? "Start selling by creating your first listing!" : `${profile.username} hasn't listed any items yet.`}
								</p>
							</div>
						{/if}
						
					{:else if activeTab === 'reviews'}
						<!-- Reviews Tab -->
						{#if reviews.length > 0}
							<div class="space-y-4">
								{#each reviews as review}
									<div class="bg-white rounded-lg shadow-sm border p-6">
										<div class="flex items-start gap-4">
											<img 
												src={review.rater?.avatar_url || `https://api.dicebear.com/7.x/avataaars/svg?seed=${review.rater?.username}`}
												alt={review.rater?.username}
												class="w-10 h-10 rounded-full"
											/>
											<div class="flex-1">
												<div class="flex items-center gap-3 mb-2">
													<h4 class="font-medium text-gray-900">
														{review.rater?.full_name || review.rater?.username}
													</h4>
													<RatingStars rating={review.rating} size="sm" />
													<Badge variant="outline" class="text-xs">
														Verified Purchase
													</Badge>
												</div>
												
												{#if review.review_text}
													<p class="text-gray-700 mb-3">{review.review_text}</p>
												{/if}
												
												{#if review.listing}
													<div class="flex items-center gap-2 text-sm text-gray-600">
														<span>For:</span>
														<span class="font-medium">{review.listing.title}</span>
													</div>
												{/if}
												
												<div class="flex items-center gap-4 mt-3 text-sm text-gray-500">
													<div class="flex items-center gap-1">
														<Calendar class="w-4 h-4" />
														<span>{formatDate(review.created_at)}</span>
													</div>
													
													{#if review.helpful_count > 0}
														<span>{review.helpful_count} helpful</span>
													{/if}
												</div>
											</div>
										</div>
									</div>
								{/each}
							</div>
						{:else}
							<div class="text-center py-12">
								<div class="text-gray-400 text-6xl mb-4">⭐</div>
								<h3 class="text-lg font-medium text-gray-900 mb-2">No reviews yet</h3>
								<p class="text-gray-600">
									{isOwnProfile ? "Reviews from buyers will appear here." : `${profile.username} doesn't have any reviews yet.`}
								</p>
							</div>
						{/if}
						
					{:else if activeTab === 'about'}
						<!-- About Tab -->
						<div class="bg-white rounded-lg shadow-sm border p-6">
							<h3 class="text-lg font-semibold text-gray-900 mb-4">About {profile.username}</h3>
							
							{#if profile.bio}
								<p class="text-gray-700 mb-6 leading-relaxed">{profile.bio}</p>
							{/if}
							
							<div class="space-y-4">
								<div class="flex justify-between items-center py-2 border-b border-gray-100">
									<span class="text-gray-600">Member since</span>
									<span class="font-medium">{formatDate(profile.member_since)}</span>
								</div>
								
								{#if profile.location}
									<div class="flex justify-between items-center py-2 border-b border-gray-100">
										<span class="text-gray-600">Location</span>
										<span class="font-medium">{profile.location}</span>
									</div>
								{/if}
								
								<div class="flex justify-between items-center py-2 border-b border-gray-100">
									<span class="text-gray-600">Response time</span>
									<span class="font-medium">
										{profile.response_time_hours < 24 ? `${profile.response_time_hours} hours` : 'Within a day'}
									</span>
								</div>
								
								{#if profile.total_sales > 0}
									<div class="flex justify-between items-center py-2 border-b border-gray-100">
										<span class="text-gray-600">Total sales</span>
										<span class="font-medium">{profile.total_sales.toLocaleString()}</span>
									</div>
								{/if}
							</div>
						</div>
					{/if}
				</div>
				
				<!-- Sidebar -->
				<div class="space-y-6">
					<!-- Stats Component -->
					<ProfileStats {profile} showDetailedStats={true} />
					
					<!-- Quick Contact (for non-own profiles) -->
					{#if !isOwnProfile}
						<div class="bg-white rounded-lg shadow-sm border p-6">
							<h3 class="text-lg font-semibold text-gray-900 mb-4">Quick Contact</h3>
							<button 
								class="w-full bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 flex items-center justify-center gap-2"
								on:click={handleMessage}
							>
								<MessageCircle class="w-4 h-4" />
								Send Message
							</button>
						</div>
					{/if}
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
				on:click={() => goto('/')}
			>
				Go Home
			</button>
		</div>
	</div>
{/if}