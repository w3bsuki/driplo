<script lang="ts">
	import { page } from '$app/stores';
	import { cn } from '$lib/utils';
	import { Filter, Search, Camera, Heart, ShoppingCart } from 'lucide-svelte';
	import MobileFiltersDrawer from './MobileFiltersDrawer.svelte';
	import * as m from '$lib/paraglide/messages.js';
	
	let showFilters = $state(false);
	
	const navItems = $derived([
		{ href: '#filters', icon: Filter, label: m.nav_filters(), isAction: true },
		{ href: '/browse', icon: Search, label: m.nav_buy() },
		{ href: '/sell', icon: Camera, label: m.nav_sell(), isPrimary: true },
		{ href: '/wishlist', icon: Heart, label: m.nav_wishlist() },
		{ href: '/cart', icon: ShoppingCart, label: m.nav_cart() }
	]);
	
	function handleNavClick(item: any) {
		if (item.isAction && item.href === '#filters') {
			showFilters = true;
		}
	}
</script>

<nav class="fixed bottom-0 left-0 right-0 z-50 bg-white/98 backdrop-blur-xl border-t border-gray-100 block md:hidden shadow-[0_-4px_20px_rgba(0,0,0,0.08)]">
	<div class="safe-area-bottom">
		<div class="flex items-center justify-around px-3 py-2">
			{#each navItems as item}
				{@const isActive = item.href && !item.isAction ? $page.url.pathname === item.href : false}
				{@const Icon = item.icon}
				
				<button
					onclick={item.isAction ? () => handleNavClick(item) : () => item.href && (window.location.href = item.href)}
					class={cn(
						"relative flex flex-col items-center justify-center min-h-[52px] min-w-[64px] px-3 py-2 rounded-2xl transition-all duration-300 transform",
						item.isPrimary
							? "bg-gradient-to-br from-orange-500 to-orange-600 text-white shadow-lg hover:shadow-xl hover:scale-105 active:scale-95"
							: isActive
								? "text-orange-600"
								: "text-gray-500 hover:text-gray-700 active:scale-95"
					)}
					aria-label={item.label}
					aria-current={isActive ? 'page' : undefined}
				>
					<div class={cn(
						"relative transition-all duration-300",
						item.isPrimary && "animate-subtle-bounce"
					)}>
						<Icon class={cn(
							"transition-all duration-300",
							item.isPrimary ? "h-5 w-5" : "h-6 w-6",
							isActive && !item.isPrimary && "stroke-[2.5]"
						)} />
						
						{#if item.isPrimary}
							<div class="absolute -top-1 -right-1 h-2 w-2 bg-white rounded-full animate-pulse"></div>
						{/if}
					</div>
					
					<span class={cn(
						"text-[10px] mt-1 font-medium transition-all duration-300",
						item.isPrimary ? "font-semibold" : isActive ? "font-semibold" : "font-normal"
					)}>
						{item.label}
					</span>
					
					{#if isActive && !item.isPrimary}
						<div class="absolute -bottom-0.5 left-1/2 w-4 h-0.5 bg-orange-500 rounded-full transform -translate-x-1/2 transition-all duration-300"></div>
					{/if}
				</button>
			{/each}
		</div>
	</div>
</nav>

<MobileFiltersDrawer isOpen={showFilters} onClose={() => showFilters = false} />

<style>
	.safe-area-bottom {
		padding-bottom: env(safe-area-inset-bottom);
	}
	
	@keyframes subtle-bounce {
		0%, 100% {
			transform: translateY(0);
		}
		50% {
			transform: translateY(-2px);
		}
	}
	
	.animate-subtle-bounce {
		animation: subtle-bounce 2s ease-in-out infinite;
	}
</style>