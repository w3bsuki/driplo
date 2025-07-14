<script lang="ts">
	import { Home, Search, Plus, MessageCircle, Filter } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { cn } from '$lib/utils';
	import MobileFiltersDrawer from './MobileFiltersDrawer.svelte';
	
	let isFiltersOpen = $state(false);
	
	const navItems = [
		{ href: '/', icon: Home, label: 'Home' },
		{ href: '/browse', icon: Search, label: 'Browse' },
		{ href: '/sell', icon: Plus, label: 'Sell' },
		{ href: '/messages', icon: MessageCircle, label: 'Messages' },
		{ href: null, icon: Filter, label: 'Filters', action: () => isFiltersOpen = !isFiltersOpen }
	];
	
	function closeFilters() {
		isFiltersOpen = false;
	}
</script>

<nav class="fixed bottom-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-md border-t border-gray-200 block md:hidden shadow-lg">
	<div class="safe-area-bottom">
		<div class="flex items-center justify-around px-2 py-2">
			{#each navItems as item}
				{@const isActive = item.href ? $page.url.pathname === item.href : false}
				{@const isFiltersActive = item.label === 'Filters' && isFiltersOpen}
				
				{#if item.href}
					<a 
						href={item.href}
						class={cn(
							"relative flex flex-col items-center justify-center min-h-[48px] px-3 py-2 rounded-xl transition-all duration-200",
							item.label === 'Sell'
								? "bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-md hover:shadow-lg hover:from-orange-600 hover:to-orange-700 active:scale-95"
								: isActive
									? "bg-orange-50 text-orange-600"
									: "text-gray-600 hover:text-orange-600 hover:bg-orange-50 active:scale-95"
						)}
						aria-label={item.label}
						aria-current={isActive ? 'page' : undefined}
					>
						<svelte:component 
							this={item.icon} 
							class="mb-1 h-5 w-5 transition-all duration-200"
							strokeWidth={2}
						/>
						<span class={cn(
							"text-xs font-medium transition-all duration-200",
							item.label === 'Sell' && "font-semibold"
						)}>
							{item.label}
						</span>
						
						{#if isActive && item.label !== 'Sell'}
							<div class="absolute -bottom-1 left-1/2 w-1 h-1 bg-orange-500 rounded-full transform -translate-x-1/2"></div>
						{/if}
					</a>
				{:else}
					<button 
						onclick={item.action}
						class={cn(
							"relative flex flex-col items-center justify-center min-h-[48px] px-3 py-2 rounded-xl transition-all duration-200",
							isFiltersActive
								? "bg-orange-50 text-orange-600"
								: "text-gray-600 hover:text-orange-600 hover:bg-orange-50 active:scale-95"
						)}
						aria-label={item.label}
					>
						<svelte:component 
							this={item.icon} 
							class="mb-1 h-5 w-5 transition-all duration-200"
							strokeWidth={2}
						/>
						<span class="text-xs font-medium transition-all duration-200">
							{item.label}
						</span>
						
						{#if isFiltersActive}
							<div class="absolute -bottom-1 left-1/2 w-1 h-1 bg-orange-500 rounded-full transform -translate-x-1/2"></div>
						{/if}
					</button>
				{/if}
			{/each}
		</div>
	</div>
</nav>

<!-- Mobile Filters Drawer -->
<MobileFiltersDrawer bind:isOpen={isFiltersOpen} onClose={closeFilters} />

<style>
	.safe-area-bottom {
		padding-bottom: env(safe-area-inset-bottom);
	}
</style>