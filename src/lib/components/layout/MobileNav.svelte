<script lang="ts">
	import { Home, Search, Plus, MessageCircle, User } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { cn } from '$lib/utils';
	
	const navItems = [
		{ href: '/', icon: Home, label: 'Home' },
		{ href: '/browse', icon: Search, label: 'Browse' },
		{ href: '/sell', icon: Plus, label: 'Sell' },
		{ href: '/messages', icon: MessageCircle, label: 'Messages' },
		{ href: '/profile', icon: User, label: 'Profile' }
	];
</script>

<nav class="fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-gray-200 block md:hidden">
	<div class="safe-area-bottom">
		<div class="grid grid-cols-5 h-16">
			{#each navItems as item}
				{@const isActive = $page.url.pathname === item.href}
				<a 
					href={item.href}
					class={cn(
						"relative flex flex-col items-center justify-center h-full min-h-[44px] px-1 py-2 transition-all duration-200 ease-out",
						item.label === 'Sell' 
							? "group" 
							: isActive 
								? "text-primary" 
								: "text-muted-foreground hover:text-foreground hover:bg-muted/50 active:bg-muted active:scale-95"
					)}
					aria-label={item.label}
					aria-current={isActive ? 'page' : undefined}
				>
					<div class={cn(
						"flex flex-col items-center transition-all duration-200 ease-out",
						isActive && item.label !== 'Sell' && "transform scale-105",
						item.label === 'Sell' && "relative"
					)}>
						{#if item.label === 'Sell'}
							<!-- Gradient background for Sell button -->
							<div class="absolute inset-0 bg-gradient-to-r from-orange-400 to-orange-600 rounded-xl blur-sm opacity-70 group-hover:opacity-100 transition-opacity duration-200"></div>
							<div class="relative bg-gradient-to-r from-orange-500 to-orange-600 text-white rounded-xl px-3 py-2 shadow-md group-hover:shadow-lg group-active:scale-95 transition-all duration-200">
								<div class="flex flex-col items-center gap-0.5">
									<svelte:component 
										this={item.icon} 
										class="h-5 w-5"
										strokeWidth={2.5}
									/>
									<span class="text-xs font-semibold">
										{item.label}
									</span>
								</div>
							</div>
							<!-- Pulse animation -->
							<div class="absolute inset-0 bg-gradient-to-r from-orange-400 to-orange-600 rounded-xl animate-ping opacity-20"></div>
						{:else}
							<svelte:component 
								this={item.icon} 
								class={cn(
									"transition-all duration-200 ease-out", 
									isActive ? "h-6 w-6" : "h-5 w-5"
								)}
								strokeWidth={isActive ? 2.5 : 2}
							/>
							<span class={cn(
								"mt-0.5 text-xs leading-tight transition-all duration-200 ease-out text-center",
								isActive ? "font-medium" : "font-normal"
							)}>
								{item.label}
							</span>
							{#if isActive}
								<div class="absolute -bottom-0 left-1/2 w-1 h-1 bg-primary rounded-full transform -translate-x-1/2 animate-pulse"></div>
							{/if}
						{/if}
					</div>
				</a>
			{/each}
		</div>
	</div>
</nav>

<style>
	.safe-area-bottom {
		padding-bottom: env(safe-area-inset-bottom);
	}
	
	@keyframes ping {
		75%, 100% {
			transform: scale(1.5);
			opacity: 0;
		}
	}
	
	.animate-ping {
		animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
	}
</style>