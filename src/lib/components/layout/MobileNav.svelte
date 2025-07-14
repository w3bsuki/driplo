<script lang="ts">
	import { page } from '$app/stores';
	import { cn } from '$lib/utils';
	
	const navItems = $derived([
		{ href: '/browse', emoji: '🔍', label: 'Browse' },
		{ href: '/messages', emoji: '💬', label: 'Messages' },
		{ href: '/sell', emoji: '📸', label: 'Sell', highlight: true },
		{ href: '/favorites', emoji: '❤️', label: 'Wishlist' },
		{ href: '/cart', emoji: '🛒', label: 'Cart', badge: 2 }
	]);
</script>

<nav class="fixed bottom-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-md border-t border-gray-200 block md:hidden shadow-lg">
	<div class="safe-area-bottom">
		<div class="flex items-center justify-around px-2 py-2">
			{#each navItems as item}
				{@const isActive = item.href ? $page.url.pathname === item.href : false}
				
				<a 
					href={item.href}
					class={cn(
						"relative flex flex-col items-center justify-center min-h-[48px] px-3 py-2 rounded-xl transition-all duration-200",
						item.highlight
							? "bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-md hover:shadow-lg hover:from-orange-600 hover:to-orange-700 active:scale-95"
							: isActive
								? "bg-gray-100 text-gray-900"
								: "text-gray-600 hover:text-gray-800 hover:bg-gray-50 active:scale-95"
					)}
					aria-label={item.label}
					aria-current={isActive ? 'page' : undefined}
				>
					<div class="relative">
						<span class="text-xl mb-1 transition-all duration-200">
							{item.emoji}
						</span>
						
						<!-- Cart Badge -->
						{#if item.badge && item.badge > 0}
							<span class="absolute -top-1 -right-1 h-4 w-4 rounded-full bg-orange-500 text-white text-xs font-bold flex items-center justify-center shadow-sm">
								{item.badge}
							</span>
						{/if}
					</div>
					
					<span class={cn(
						"text-xs font-medium transition-all duration-200",
						item.highlight && "font-semibold"
					)}>
						{item.label}
					</span>
					
					{#if isActive && !item.highlight}
						<div class="absolute -bottom-1 left-1/2 w-1 h-1 bg-gray-800 rounded-full transform -translate-x-1/2"></div>
					{/if}
				</a>
			{/each}
		</div>
	</div>
</nav>


<style>
	.safe-area-bottom {
		padding-bottom: env(safe-area-inset-bottom);
	}
</style>