<script lang="ts">
	import { Badge } from '$lib/components/ui/badge'
	import { TrendingUp, Star, Clock, Package, Award, Eye } from 'lucide-svelte'
	import type { EnhancedUserProfile, SellerMetrics } from '$lib/types/social'
	
	interface Props {
		profile: EnhancedUserProfile
		metrics?: SellerMetrics
		showDetailedStats?: boolean
	}
	
	let { profile, metrics, showDetailedStats = false }: Props = $props()
	
	// Calculate seller performance indicators
	$: sellerPerformance = {
		rating: profile.seller_rating,
		ratingCount: profile.seller_rating_count,
		responseTime: profile.response_time_hours,
		totalSales: profile.total_sales,
		completionRate: profile.completion_percentage,
		isTopRated: profile.seller_rating >= 4.5 && profile.seller_rating_count >= 10,
		isFastShipper: profile.response_time_hours <= 12,
		isPowerSeller: profile.total_sales >= 50
	}
	
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

<div class="bg-white rounded-xl shadow-sm border p-6 space-y-6">
	<!-- Performance Overview -->
	<div class="flex items-center justify-between">
		<h3 class="text-lg font-semibold text-gray-900">Seller Performance</h3>
		
		{#if sellerPerformance.isTopRated}
			<Badge class="bg-gradient-to-r from-yellow-400 to-orange-500 text-white">
				<Star class="w-3 h-3 mr-1" />
				Top Rated
			</Badge>
		{/if}
	</div>
	
	<!-- Key Metrics Grid -->
	<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
		<!-- Rating -->
		<div class="text-center p-4 bg-gray-50 rounded-lg">
			<div class="flex items-center justify-center gap-1 mb-2">
				<span class="text-2xl font-bold text-gray-900">
					{sellerPerformance.rating > 0 ? sellerPerformance.rating.toFixed(1) : 'N/A'}
				</span>
				{#if sellerPerformance.rating > 0}
					<Star class="w-5 h-5 text-yellow-500 fill-current" />
				{/if}
			</div>
			<p class="text-sm text-gray-600">
				{sellerPerformance.ratingCount} reviews
			</p>
		</div>
		
		<!-- Total Sales -->
		<div class="text-center p-4 bg-gray-50 rounded-lg">
			<div class="text-2xl font-bold text-gray-900 mb-2">
				{sellerPerformance.totalSales.toLocaleString()}
			</div>
			<p class="text-sm text-gray-600">Total Sales</p>
		</div>
		
		<!-- Response Time -->
		<div class="text-center p-4 bg-gray-50 rounded-lg">
			<div class="flex items-center justify-center gap-1 mb-2">
				<Clock class="w-4 h-4 {getResponseTimeColor(sellerPerformance.responseTime)}" />
				<span class="text-lg font-bold {getResponseTimeColor(sellerPerformance.responseTime)}">
					{sellerPerformance.responseTime}h
				</span>
			</div>
			<p class="text-sm text-gray-600">Response Time</p>
		</div>
		
		<!-- Profile Views -->
		<div class="text-center p-4 bg-gray-50 rounded-lg">
			<div class="flex items-center justify-center gap-1 mb-2">
				<Eye class="w-4 h-4 text-gray-600" />
				<span class="text-lg font-bold text-gray-900">
					{profile.profile_views.toLocaleString()}
				</span>
			</div>
			<p class="text-sm text-gray-600">Profile Views</p>
		</div>
	</div>
	
	<!-- Performance Badges -->
	<div class="flex flex-wrap gap-2">
		{#if sellerPerformance.isTopRated}
			<Badge class="bg-yellow-100 text-yellow-800 border-yellow-300">
				<Star class="w-3 h-3 mr-1" />
				Top Rated Seller
			</Badge>
		{/if}
		
		{#if sellerPerformance.isFastShipper}
			<Badge class="bg-green-100 text-green-800 border-green-300">
				<Clock class="w-3 h-3 mr-1" />
				Fast Shipper
			</Badge>
		{/if}
		
		{#if sellerPerformance.isPowerSeller}
			<Badge class="bg-blue-100 text-blue-800 border-blue-300">
				<TrendingUp class="w-3 h-3 mr-1" />
				Power Seller
			</Badge>
		{/if}
		
		{#if profile.verification_badges.includes('business')}
			<Badge class="bg-purple-100 text-purple-800 border-purple-300">
				<Award class="w-3 h-3 mr-1" />
				Business Verified
			</Badge>
		{/if}
	</div>
	
	{#if showDetailedStats && metrics}
		<!-- Detailed Metrics -->
		<div class="border-t pt-6 space-y-4">
			<h4 class="font-medium text-gray-900">Detailed Performance</h4>
			
			<!-- Completion Rate -->
			<div class="space-y-2">
				<div class="flex justify-between text-sm">
					<span class="text-gray-600">Order Completion Rate</span>
					<span class="font-medium">{metrics.completion_rate}%</span>
				</div>
				<div class="w-full bg-gray-200 rounded-full h-2">
					<div 
						class="h-2 rounded-full {getPerformanceBadgeColor(metrics.completion_rate)}"
						style="width: {metrics.completion_rate}%"
					></div>
				</div>
			</div>
			
			<!-- Repeat Customer Rate -->
			<div class="space-y-2">
				<div class="flex justify-between text-sm">
					<span class="text-gray-600">Repeat Customer Rate</span>
					<span class="font-medium">{metrics.repeat_customer_rate}%</span>
				</div>
				<div class="w-full bg-gray-200 rounded-full h-2">
					<div 
						class="h-2 rounded-full {getPerformanceBadgeColor(metrics.repeat_customer_rate)}"
						style="width: {metrics.repeat_customer_rate}%"
					></div>
				</div>
			</div>
			
			<!-- 30-Day Performance -->
			<div class="grid grid-cols-2 gap-4 pt-4 border-t">
				<div class="text-center">
					<div class="text-lg font-bold text-gray-900">
						{metrics.items_sold_last_30_days}
					</div>
					<p class="text-sm text-gray-600">Items Sold (30d)</p>
				</div>
				<div class="text-center">
					<div class="text-lg font-bold text-gray-900">
						{formatEarnings(metrics.revenue_last_30_days)}
					</div>
					<p class="text-sm text-gray-600">Revenue (30d)</p>
				</div>
			</div>
		</div>
	{/if}
</div>