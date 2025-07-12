<script lang="ts">
	import { Home, Search, Camera, MessageCircle, User } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { cn } from '$lib/utils';
	
	const navItems = [
		{ href: '/', icon: Home, label: 'Home' },
		{ href: '/browse', icon: Search, label: 'Browse' },
		{ href: '/sell', icon: Camera, label: 'Sell', accent: true },
		{ href: '/messages', icon: MessageCircle, label: 'Messages' },
		{ href: '/profile', icon: User, label: 'Profile' }
	];
</script>

<nav class="fixed bottom-0 left-0 right-0 z-50 bg-background border-t md:hidden">
	<div class="flex items-center justify-around h-16">
		{#each navItems as item}
			{@const isActive = $page.url.pathname === item.href}
			<a 
				href={item.href}
				class={cn(
					"flex flex-col items-center justify-center flex-1 h-full transition-colors",
					isActive && "text-primary",
					item.accent && "text-primary"
				)}
			>
				<svelte:component this={item.icon} class={cn("h-5 w-5", item.accent && "h-6 w-6")} />
				<span class="text-xs mt-1">{item.label}</span>
			</a>
		{/each}
	</div>
</nav>