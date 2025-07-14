<script lang="ts">
	import { Search, Heart, MessageCircle, User, Menu, X, Camera, Home, LogOut } from 'lucide-svelte';
	import { Button } from '$lib/components/ui';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import { user, profile, auth } from '$lib/stores/auth';
	import type { Category } from '$lib/types';
	
	interface Props {
		categories?: Category[];
	}
	
	let { categories = [] }: Props = $props();
	
	let isMenuOpen = $state(false);
	let searchQuery = $state('');
	let activeCategory = $state('');
	
	const quickCategories = $derived([
		{ name: 'All', value: '', slug: '', icon: '🔍' },
		...categories.map(cat => ({ 
			name: cat.name, 
			value: cat.slug, 
			slug: cat.slug,
			icon: cat.icon || '📦'
		}))
	]);

	function handleSearch() {
		if (searchQuery.trim()) {
			const params = new URLSearchParams();
			params.set('q', searchQuery.trim());
			goto(`/browse?${params.toString()}`);
		} else {
			goto('/browse');
		}
	}

	function selectCategory(category: string) {
		activeCategory = category;
		if (category) {
			// Navigate to dedicated category page
			goto(`/${category}`);
		} else {
			// Navigate to browse all
			goto('/browse');
		}
	}

	function toggleMenu() {
		isMenuOpen = !isMenuOpen;
	}

	function closeMenu() {
		isMenuOpen = false;
	}
</script>

<header class="sticky top-0 z-50 w-full border-b bg-white">
	<!-- Main Header -->
	<div class="container flex h-16 items-center px-4">
		<!-- Mobile Menu Button (Left) -->
		<div class="flex md:hidden items-center mr-1">
			<Button 
				variant="ghost" 
				size="icon"
				onclick={toggleMenu}
				class="h-11 w-11 hover:bg-orange-50 border-0 rounded-xl transition-colors"
				aria-label="Toggle menu"
				aria-expanded={isMenuOpen}
			>
				{#if isMenuOpen}
					<X class="h-5 w-5 text-orange-600" />
				{:else}
					<Menu class="h-5 w-5 text-orange-600" />
				{/if}
			</Button>
		</div>
		
		<!-- Logo -->
		<a href="/" class="flex items-center space-x-2 mr-4 md:mr-6">
			<span class="text-xl md:text-2xl font-bold text-primary hover:text-primary/90 transition-colors tracking-tight">Driplo</span>
		</a>

		<!-- Desktop Search Bar -->
		<div class="flex-1 max-w-2xl mx-2 md:mx-4 hidden md:block">
			<div class="relative">
				<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
				<input
					type="search"
					placeholder="Search for items, brands, or users..."
					bind:value={searchQuery}
					onkeydown={(e) => e.key === 'Enter' && handleSearch()}
					class="w-full rounded-xl border border-input bg-background pl-10 pr-4 py-2.5 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2 transition-all hover:border-orange-200"
				/>
			</div>
		</div>

		<!-- Desktop Actions -->
		<div class="hidden md:flex items-center space-x-2">
			<button class="relative p-2 hover:bg-muted rounded-lg transition-colors">
				<Heart class="h-5 w-5 text-muted-foreground hover:text-foreground" />
				<span class="sr-only">Favorites</span>
			</button>
			<a href="/messages" class="relative p-2 hover:bg-muted rounded-lg transition-colors">
				<MessageCircle class="h-5 w-5 text-muted-foreground hover:text-foreground" />
				<span class="sr-only">Messages</span>
			</a>
			<a href={$user ? ($profile?.username ? `/profile/${$profile.username}` : '/profile') : '/login'} class="relative p-2 hover:bg-orange-50 rounded-lg transition-colors group">
				{#if $user}
					<div class="h-8 w-8 rounded-full bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-sm">
						<User class="h-4 w-4 text-white" />
					</div>
				{:else}
					<div class="h-8 w-8 rounded-full border-2 border-orange-200 hover:border-orange-300 bg-white flex items-center justify-center group-hover:bg-orange-50 transition-colors">
						<User class="h-4 w-4 text-orange-600" />
					</div>
				{/if}
				<span class="sr-only">{$user ? 'Profile' : 'Sign in'}</span>
			</a>
		</div>

		<!-- Mobile Actions -->
		<div class="flex md:hidden items-center gap-2 ml-auto">
			<a href={$user ? ($profile?.username ? `/profile/${$profile.username}` : '/profile') : '/login'} class="relative p-2 hover:bg-orange-50 rounded-lg transition-colors group">
				{#if $user}
					<div class="h-8 w-8 rounded-full bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-sm">
						<User class="h-4 w-4 text-white" />
					</div>
				{:else}
					<div class="h-8 w-8 rounded-full border-2 border-orange-200 hover:border-orange-300 bg-white flex items-center justify-center group-hover:bg-orange-50 transition-colors">
						<User class="h-4 w-4 text-orange-600" />
					</div>
				{/if}
				<span class="sr-only">{$user ? 'Profile' : 'Sign in'}</span>
			</a>
		</div>
	</div>


	<!-- Category Filter Chips (Desktop) -->
	<div class="hidden md:block border-t bg-white">
		<div class="container px-4 py-3">
			<div class="flex items-center space-x-2 overflow-x-auto">
				{#each quickCategories as category}
					<button
						onclick={() => selectCategory(category.value)}
						class={cn(
							"whitespace-nowrap rounded-full px-4 py-2 text-sm font-medium transition-all duration-200",
							activeCategory === category.value
								? "bg-primary text-primary-foreground shadow-sm hover:bg-primary/90"
								: "bg-muted hover:bg-orange-50 text-muted-foreground hover:text-orange-600"
						)}
					>
						{category.name}
					</button>
				{/each}
			</div>
		</div>
	</div>

	<!-- Mobile Menu Overlay & Panel -->
	{#if isMenuOpen}
		<!-- Backdrop -->
		<button 
			type="button"
			class="fixed top-0 left-0 right-0 bottom-0 z-[99]" 
			style="background-color: rgba(0, 0, 0, 0.5);"
			onclick={closeMenu}
			aria-label="Close menu"
		></button>
		
		<!-- Slide-out Panel -->
		<div class="fixed top-0 right-0 bottom-0 z-[100] w-72 max-w-[85vw] shadow-2xl border-l border-gray-200" style="background-color: #ffffff !important; opacity: 1 !important;">
			<div class="flex h-full flex-col">
				<!-- Header -->
				<div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
					<h2 class="text-lg font-semibold text-gray-900">Menu</h2>
					<button 
						onclick={closeMenu}
						class="h-8 w-8 flex items-center justify-center rounded-lg hover:bg-orange-50 transition-colors"
						aria-label="Close menu"
					>
						<X class="h-4 w-4 text-orange-600" />
					</button>
				</div>

				<!-- Navigation -->
				<nav class="flex-1 overflow-y-auto px-4 py-6">
					<div class="space-y-1">
						<a 
							href="/" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100"
						>
							<Home class="h-4 w-4" />
							Home
						</a>
						<a 
							href="/browse" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100"
						>
							<Search class="h-4 w-4" />
							Browse
						</a>
						<a 
							href="/sell" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100"
						>
							<Camera class="h-4 w-4" />
							Sell Item
						</a>
						<a 
							href="/messages" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100"
						>
							<MessageCircle class="h-4 w-4" />
							Messages
						</a>
						<a 
							href={$user ? ($profile?.username ? `/profile/${$profile.username}` : '/profile') : '/login'} 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-orange-700 transition-colors hover:bg-orange-50 border border-orange-200 hover:border-orange-300"
						>
							{#if $user}
								<div class="h-5 w-5 rounded-full bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center">
									<User class="h-3 w-3 text-white" />
								</div>
							{:else}
								<User class="h-4 w-4 text-orange-600" />
							{/if}
							{$user ? 'Profile' : 'Sign in'}
						</a>
						<a 
							href="/favorites" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100"
						>
							<Heart class="h-4 w-4" />
							Favorites
						</a>
					</div>
					
					<!-- Categories Section -->
					{#if categories.length > 0}
						<div class="mt-6 pt-6 border-t border-gray-200">
							<h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Categories</h3>
							<div class="space-y-1">
								{#each categories as category}
									<a 
										href="/{category.slug}"
										onclick={closeMenu}
										class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100"
									>
										<span class="text-base">{category.icon || '📦'}</span>
										{category.name}
									</a>
								{/each}
							</div>
						</div>
					{/if}
					
					<div class="mt-6 space-y-1">
						{#if $user}
							<a 
								href="/profile/settings" 
								onclick={closeMenu}
								class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-orange-600 transition-colors hover:bg-orange-50 hover:text-orange-700"
							>
								<User class="h-4 w-4 text-orange-600" />
								Settings
							</a>
						{/if}
					</div>
				</nav>

				<!-- Footer -->
				<div class="border-t border-gray-200 px-4 py-4">
					<button 
						onclick={() => {closeMenu(); goto('/sell');}}
						class="w-full bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white py-3 px-4 rounded-xl font-medium shadow-md hover:shadow-lg transition-all duration-200 flex items-center justify-center gap-2"
					>
						<Camera class="h-4 w-4" />
						Sell an Item
					</button>
				</div>
			</div>
		</div>
	{/if}
</header>