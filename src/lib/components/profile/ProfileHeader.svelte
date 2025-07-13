<script lang="ts">
	import { Badge } from '$lib/components/ui/badge'
	import { Button } from '$lib/components/ui'
	import { Camera, MapPin, Calendar, ExternalLink, MessageCircle, UserPlus, UserMinus } from 'lucide-svelte'
	import type { EnhancedUserProfile } from '$lib/types/social'
	import { getAchievementIcon, getAchievementColor } from '$lib/data/achievements'
	import { auth } from '$lib/stores/auth'
	
	interface Props {
		profile: EnhancedUserProfile
		isOwnProfile?: boolean
		isFollowing?: boolean
		onFollow?: () => void
		onMessage?: () => void
		onEditProfile?: () => void
	}
	
	let { 
		profile, 
		isOwnProfile = false, 
		isFollowing = false,
		onFollow,
		onMessage,
		onEditProfile
	}: Props = $props()
	
	// Calculate profile completion percentage
	$: completionScore = calculateCompletionScore(profile)
	
	function calculateCompletionScore(profile: EnhancedUserProfile): number {
		let score = 0
		const fields = [
			profile.avatar_url,
			profile.cover_image_url,
			profile.bio,
			profile.location,
			profile.full_name,
			profile.verification_badges?.length > 0,
			Object.keys(profile.social_links || {}).length > 0
		]
		
		fields.forEach(field => {
			if (field) score += 14.3 // ~100/7 fields
		})
		
		return Math.round(score)
	}
	
	function formatMemberSince(dateString: string): string {
		const date = new Date(dateString)
		return date.toLocaleDateString('en-US', { 
			month: 'long', 
			year: 'numeric' 
		})
	}
	
	function getVerificationBadges(badges: string[]): string[] {
		return badges?.filter(badge => ['email', 'phone', 'id', 'business'].includes(badge)) || []
	}
</script>

<!-- Cover Image Section -->
<div class="relative h-48 md:h-64 bg-gradient-to-br from-orange-100 to-pink-100 overflow-hidden">
	{#if profile.cover_image_url}
		<img 
			src={profile.cover_image_url} 
			alt="Cover" 
			class="w-full h-full object-cover"
		/>
	{:else}
		<!-- Default gradient cover -->
		<div class="absolute inset-0 bg-gradient-to-br from-orange-200 via-pink-200 to-purple-200 opacity-50"></div>
		<div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent"></div>
	{/if}
	
	<!-- Edit Cover Button (own profile only) -->
	{#if isOwnProfile}
		<button 
			class="absolute top-4 right-4 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-colors"
			on:click={onEditProfile}
		>
			<Camera class="w-4 h-4" />
		</button>
	{/if}
</div>

<!-- Profile Info Section -->
<div class="relative px-4 md:px-6 pb-6">
	<!-- Avatar -->
	<div class="relative -mt-16 md:-mt-20 mb-4">
		<div class="relative inline-block">
			<img 
				src={profile.avatar_url || `https://api.dicebear.com/7.x/avataaars/svg?seed=${profile.username}`} 
				alt={profile.full_name || profile.username}
				class="w-24 h-24 md:w-32 md:h-32 rounded-full border-4 border-white shadow-lg bg-white object-cover"
			/>
			
			<!-- Online/Verification Status -->
			<div class="absolute bottom-2 right-2 flex items-center gap-1">
				{#if getVerificationBadges(profile.verification_badges).length > 0}
					<div class="bg-blue-500 text-white p-1 rounded-full">
						<svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
							<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
						</svg>
					</div>
				{/if}
			</div>
			
			<!-- Edit Avatar Button (own profile only) -->
			{#if isOwnProfile}
				<button 
					class="absolute bottom-0 right-0 bg-gray-800 hover:bg-gray-700 text-white p-2 rounded-full shadow-lg transition-colors"
					on:click={onEditProfile}
				>
					<Camera class="w-3 h-3" />
				</button>
			{/if}
		</div>
	</div>
	
	<!-- Name and Username -->
	<div class="mb-4">
		<div class="flex items-center gap-3 flex-wrap">
			<h1 class="text-2xl md:text-3xl font-bold text-gray-900">
				{profile.full_name || profile.username}
			</h1>
			
			<!-- Verification Badges -->
			{#each getVerificationBadges(profile.verification_badges) as badge}
				<Badge variant="secondary" class="text-xs">
					✅ {badge}
				</Badge>
			{/each}
			
			<!-- Seller Level Badge -->
			{#if profile.seller_level > 1}
				<Badge class="bg-gradient-to-r from-orange-500 to-red-500 text-white">
					Level {profile.seller_level}
				</Badge>
			{/if}
		</div>
		
		<p class="text-gray-600 text-lg">@{profile.username}</p>
		
		{#if profile.bio}
			<p class="text-gray-700 mt-2 max-w-2xl leading-relaxed">{profile.bio}</p>
		{/if}
	</div>
	
	<!-- Stats Row -->
	<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
		<!-- Seller Rating -->
		{#if profile.seller_rating_count > 0}
			<div class="text-center">
				<div class="flex items-center justify-center gap-1 mb-1">
					<span class="text-xl md:text-2xl font-bold text-gray-900">
						{profile.seller_rating.toFixed(1)}
					</span>
					<span class="text-yellow-500 text-lg">⭐</span>
				</div>
				<p class="text-sm text-gray-600">
					{profile.seller_rating_count} reviews
				</p>
			</div>
		{/if}
		
		<!-- Total Sales -->
		<div class="text-center">
			<div class="text-xl md:text-2xl font-bold text-gray-900 mb-1">
				{profile.total_sales}
			</div>
			<p class="text-sm text-gray-600">Sales</p>
		</div>
		
		<!-- Followers -->
		<div class="text-center">
			<div class="text-xl md:text-2xl font-bold text-gray-900 mb-1">
				{profile.followers_count.toLocaleString()}
			</div>
			<p class="text-sm text-gray-600">Followers</p>
		</div>
		
		<!-- Following -->
		<div class="text-center">
			<div class="text-xl md:text-2xl font-bold text-gray-900 mb-1">
				{profile.following_count.toLocaleString()}
			</div>
			<p class="text-sm text-gray-600">Following</p>
		</div>
	</div>
	
	<!-- Achievement Badges -->
	{#if profile.achievements && profile.achievements.length > 0}
		<div class="mb-6">
			<h3 class="text-sm font-semibold text-gray-700 mb-2 uppercase tracking-wide">
				Achievements
			</h3>
			<div class="flex flex-wrap gap-2">
				{#each profile.achievements.slice(0, 6) as achievement}
					<div 
						class="flex items-center gap-1 px-3 py-1.5 rounded-full text-sm font-medium text-white {getAchievementColor(achievement.achievement_type)}"
						title="{achievement.achievement_type} - Level {achievement.level}"
					>
						<span class="text-sm">{getAchievementIcon(achievement.achievement_type)}</span>
						<span class="hidden sm:inline">Level {achievement.level}</span>
					</div>
				{/each}
				
				{#if profile.achievements.length > 6}
					<Badge variant="outline" class="text-xs">
						+{profile.achievements.length - 6} more
					</Badge>
				{/if}
			</div>
		</div>
	{/if}
	
	<!-- Meta Information -->
	<div class="flex flex-wrap items-center gap-4 text-sm text-gray-600 mb-6">
		{#if profile.location}
			<div class="flex items-center gap-1">
				<MapPin class="w-4 h-4" />
				<span>{profile.location}</span>
			</div>
		{/if}
		
		<div class="flex items-center gap-1">
			<Calendar class="w-4 h-4" />
			<span>Member since {formatMemberSince(profile.member_since)}</span>
		</div>
		
		{#if profile.website}
			<a 
				href={profile.website} 
				target="_blank" 
				rel="noopener noreferrer"
				class="flex items-center gap-1 text-orange-600 hover:text-orange-700 transition-colors"
			>
				<ExternalLink class="w-4 h-4" />
				<span>Website</span>
			</a>
		{/if}
		
		{#if profile.response_time_hours < 24}
			<div class="flex items-center gap-1 text-green-600">
				<span class="w-2 h-2 bg-green-500 rounded-full"></span>
				<span>Usually responds within {profile.response_time_hours}h</span>
			</div>
		{/if}
	</div>
	
	<!-- Action Buttons -->
	<div class="flex flex-wrap gap-3">
		{#if isOwnProfile}
			<!-- Own Profile Actions -->
			<Button 
				variant="outline" 
				class="flex-1 sm:flex-none"
				on:click={onEditProfile}
			>
				Edit Profile
			</Button>
			
			{#if completionScore < 100}
				<Badge variant="outline" class="text-xs">
					Profile {completionScore}% complete
				</Badge>
			{/if}
		{:else}
			<!-- Other User Actions -->
			<Button 
				class="flex-1 sm:flex-none bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
				on:click={onFollow}
			>
				{#if isFollowing}
					<UserMinus class="w-4 h-4 mr-2" />
					Unfollow
				{:else}
					<UserPlus class="w-4 h-4 mr-2" />
					Follow
				{/if}
			</Button>
			
			<Button 
				variant="outline" 
				class="flex-1 sm:flex-none"
				on:click={onMessage}
			>
				<MessageCircle class="w-4 h-4 mr-2" />
				Message
			</Button>
		{/if}
	</div>
</div>