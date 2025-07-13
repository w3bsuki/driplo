<script lang="ts">
	import { Badge } from '$lib/components/ui/badge'
	import { TrendingUp, Star, Clock, Package, Award, Eye, DollarSign, Shield } from 'lucide-svelte'
	import type { EnhancedUserProfile, SellerMetrics } from '$lib/types/social'
	
	interface Props {
		profile: EnhancedUserProfile
		metrics?: SellerMetrics
		showDetailedStats?: boolean
	}
	
	let { profile, metrics, showDetailedStats = false }: Props = $props()
	
	// Calculate seller performance indicators
	const sellerPerformance = $derived({
		rating: profile.seller_rating,
		ratingCount: profile.seller_rating_count,
		responseTime: profile.response_time_hours,
		totalSales: profile.total_sales,
		completionRate: profile.completion_percentage,
		isTopRated: profile.seller_rating >= 4.5 && profile.seller_rating_count >= 10,
		isFastShipper: profile.response_time_hours <= 12,
		isPowerSeller: profile.total_sales >= 50
	})
	
	function formatEarnings(amount: number): string {
		if (amount >= 1000) {
			return `$${(amount / 1000).toFixed(1)}k`
		}
		return `$${amount.toFixed(0)}`
	}
	
	function getPerformanceBadgeColor(percentage: number): string {
		if (percentage >= 95) return 'bg-green-500'
		if (percentage >= 85) return 'bg-yellow-500'
		if (percentage >= 70) return 'bg-orange-500'
		return 'bg-red-500'
	}
	
	function getResponseTimeColor(hours: number): string {
		if (hours <= 2) return 'text-green-600'
		if (hours <= 12) return 'text-yellow-600'
		if (hours <= 24) return 'text-orange-600'
		return 'text-red-600'
	}
</script>

<!-- Mobile-First Stats Card -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
	<!-- Header with Orange Gradient -->
	<div class="bg-gradient-to-r from-orange-500 to-red-500 p-4 text-white">
		<h3 class="text-lg font-semibold flex items-center gap-2">
			<TrendingUp class="w-5 h-5" />
			Seller Performance
		</h3>
	</div>
	
	<!-- Stats Content -->
	<div class="p-4 space-y-4">
		<!-- Quick Stats Grid - 2x2 on Mobile -->
		<div class="grid grid-cols-2 gap-3">
			<!-- Rating -->
			<div class="bg-orange-50 rounded-xl p-3 text-center">
				<div class="flex items-center justify-center gap-1 mb-1">
					<span class="text-xl font-bold text-gray-900">
						{sellerPerformance.rating > 0 ? sellerPerformance.rating.toFixed(1) : 'N/A'}
					</span>
					{#if sellerPerformance.rating > 0}
						<Star class="w-4 h-4 text-orange-500 fill-current" />
					{/if}
				</div>
				<p class="text-xs text-gray-600">
					{sellerPerformance.ratingCount} reviews
				</p>
			</div>
			
			<!-- Total Sales -->
			<div class="bg-orange-50 rounded-xl p-3 text-center">
				<div class="text-xl font-bold text-gray-900 mb-1">
					{sellerPerformance.totalSales}
				</div>
				<p class="text-xs text-gray-600">Total Sales</p>
			</div>
			
			<!-- Response Time -->
			<div class="bg-gray-50 rounded-xl p-3 text-center">
				<div class="flex items-center justify-center gap-1 mb-1">
					<Clock class="w-4 h-4 {getResponseTimeColor(sellerPerformance.responseTime)}" />
					<span class="text-lg font-bold {getResponseTimeColor(sellerPerformance.responseTime)}">
						{sellerPerformance.responseTime}h
					</span>
				</div>
				<p class="text-xs text-gray-600">Response</p>
			</div>
			
			<!-- Profile Views -->
			<div class="bg-gray-50 rounded-xl p-3 text-center">
				<div class="flex items-center justify-center gap-1 mb-1">
					<Eye class="w-4 h-4 text-gray-600" />
					<span class="text-lg font-bold text-gray-900">
						{profile.profile_views >= 1000 
							? `${(profile.profile_views / 1000).toFixed(1)}k` 
							: profile.profile_views
						}
					</span>
				</div>
				<p class="text-xs text-gray-600">Views</p>
			</div>
		</div>
		
		<!-- Achievement Badges -->
		<div class="space-y-2">
			{#if sellerPerformance.isTopRated || sellerPerformance.isFastShipper || sellerPerformance.isPowerSeller}
				<div class="flex flex-wrap gap-2">
					{#if sellerPerformance.isTopRated}
						<div class="flex items-center gap-1.5 bg-gradient-to-r from-orange-100 to-yellow-100 text-orange-800 px-3 py-1.5 rounded-full text-xs font-medium">
							<Star class="w-3.5 h-3.5" />
							Top Rated
						</div>
					{/if}
					
					{#if sellerPerformance.isFastShipper}
						<div class="flex items-center gap-1.5 bg-green-100 text-green-800 px-3 py-1.5 rounded-full text-xs font-medium">
							<Clock class="w-3.5 h-3.5" />
							Fast Shipper
						</div>
					{/if}
					
					{#if sellerPerformance.isPowerSeller}
						<div class="flex items-center gap-1.5 bg-blue-100 text-blue-800 px-3 py-1.5 rounded-full text-xs font-medium">
							<TrendingUp class="w-3.5 h-3.5" />
							Power Seller
						</div>
					{/if}
				</div>
			{/if}
			
			{#if profile.verification_badges?.includes('business')}
				<div class="flex items-center gap-1.5 bg-purple-100 text-purple-800 px-3 py-1.5 rounded-full text-xs font-medium w-fit">
					<Shield class="w-3.5 h-3.5" />
					Business Verified
				</div>
			{/if}
		</div>
		
		{#if showDetailedStats && metrics}
			<!-- Detailed Performance Section -->
			<div class="pt-3 border-t border-gray-100 space-y-3">
				<h4 class="text-sm font-semibold text-gray-900">Performance Metrics</h4>
				
				<!-- Completion Rate -->
				<div>
					<div class="flex justify-between items-center mb-1">
						<span class="text-xs text-gray-600">Order Completion</span>
						<span class="text-xs font-semibold">{metrics.completion_rate}%</span>
					</div>
					<div class="w-full bg-gray-200 rounded-full h-1.5">
						<div 
							class="h-1.5 rounded-full transition-all duration-500 {getPerformanceBadgeColor(metrics.completion_rate)}"
							style="width: {metrics.completion_rate}%"
						></div>
					</div>
				</div>
				
				<!-- Repeat Customers -->
				<div>
					<div class="flex justify-between items-center mb-1">
						<span class="text-xs text-gray-600">Repeat Customers</span>
						<span class="text-xs font-semibold">{metrics.repeat_customer_rate}%</span>
					</div>
					<div class="w-full bg-gray-200 rounded-full h-1.5">
						<div 
							class="h-1.5 rounded-full transition-all duration-500 {getPerformanceBadgeColor(metrics.repeat_customer_rate)}"
							style="width: {metrics.repeat_customer_rate}%"
						></div>
					</div>
				</div>
				
				<!-- 30-Day Stats -->
				<div class="grid grid-cols-2 gap-3 pt-2">
					<div class="bg-gray-50 rounded-lg p-2.5 text-center">
						<div class="text-base font-bold text-gray-900">
							{metrics.items_sold_last_30_days}
						</div>
						<p class="text-xs text-gray-600">Sales (30d)</p>
					</div>
					<div class="bg-green-50 rounded-lg p-2.5 text-center">
						<div class="text-base font-bold text-green-700">
							{formatEarnings(metrics.revenue_last_30_days)}
						</div>
						<p class="text-xs text-gray-600">Revenue (30d)</p>
					</div>
				</div>
			</div>
		{/if}
		
		<!-- Trust Indicators -->
		<div class="pt-3 border-t border-gray-100">
			<div class="flex items-center justify-between text-xs">
				<span class="text-gray-600">Member since {new Date(profile.member_since).getFullYear()}</span>
				{#if profile.seller_level > 1}
					<Badge class="bg-gradient-to-r from-orange-500 to-red-500 text-white text-xs">
						Level {profile.seller_level}
					</Badge>
				{/if}
			</div>
		</div>
	</div>
</div>