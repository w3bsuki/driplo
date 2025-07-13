<script lang="ts">
	import { Home, Search, Plus, User, Grid3X3 } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	
	let showCategories = $state(false);
	
	const navItems = [
		{ href: '/', icon: Home, label: 'Home' },
		{ href: '/browse', icon: Search, label: 'Browse' },
		{ action: 'categories', icon: Grid3X3, label: 'Categories', special: true },
		{ href: '/sell', icon: Plus, label: 'Sell', accent: true },
		{ href: '/profile', icon: User, label: 'Profile' }
	];

	function handleClick(item: any) {
		if (item.action === 'categories') {
			showCategories = !showCategories;
		} else if (item.href) {
			goto(item.href);
		}
	}
</script>

<nav class="fixed bottom-0 left-0 right-0 z-50 bg-white border-t md:hidden">
	<div class="flex items-center justify-around py-2">
		{#each navItems as item}
			{@const isActive = item.href && $page.url.pathname === item.href}
			<button 
				onclick={() => handleClick(item)}
				class={cn(
					"flex flex-col items-center justify-center p-2 transition-colors",
					isActive ? "text-blue-600" : "text-gray-600"
				)}
			>
				<svelte:component this={item.icon} class="h-6 w-6" />
				<span class="text-xs mt-1">{item.label}</span>
			</button>
		{/each}
	</div>
</nav>

{#if showCategories}
	<div class="fixed inset-0 z-50 md:hidden">
		<div class="fixed inset-0 bg-black bg-opacity-50" onclick={() => showCategories = false}></div>
		<div class="fixed bottom-0 left-0 right-0 bg-white rounded-t-lg p-4">
			<h3 class="text-lg font-semibold mb-4">Categories</h3>
			<div class="grid grid-cols-2 gap-2">
				{#each ['All', 'Women', 'Men', 'Kids', 'Designer', 'Shoes'] as cat}
					<button
						onclick={() => {
							showCategories = false;
							goto(`/browse?category=${cat.toLowerCase()}`);
						}}
						class="p-3 bg-gray-100 rounded-lg text-left hover:bg-gray-200"
					>
						{cat}
					</button>
				{/each}
			</div>
		</div>
	</div>
{/if}