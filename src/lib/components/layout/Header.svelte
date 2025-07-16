<script lang="ts">
	import { Search, Heart, MessageCircle, User, Menu, X, Camera, Home, LogOut, ShoppingBag } from 'lucide-svelte';
	import { Button } from '$lib/components/ui';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import { user, profile, auth } from '$lib/stores/auth';
	import type { Category } from '$lib/types';
	import * as m from '$lib/paraglide/messages.js';
	import LanguageSwitcher from './LanguageSwitcher.svelte';
	
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
		<div class="flex md:hidden items-center mr-2">
			<button
				onclick={toggleMenu}
				class="relative h-10 w-10 flex items-center justify-center rounded-xl hover:bg-gray-50 transition-all duration-200 group active:scale-95"
				aria-label="Toggle menu"
				aria-expanded={isMenuOpen}
			>
				<div class="relative w-5 h-4 flex flex-col justify-between">
					<span class={cn(
						"block h-0.5 w-full bg-gray-600 rounded-full transition-all duration-300 origin-left",
						isMenuOpen ? "rotate-45 translate-x-0.5" : ""
					)}></span>
					<span class={cn(
						"block h-0.5 w-full bg-gray-600 rounded-full transition-all duration-300",
						isMenuOpen ? "opacity-0 scale-0" : ""
					)}></span>
					<span class={cn(
						"block h-0.5 w-full bg-gray-600 rounded-full transition-all duration-300 origin-left",
						isMenuOpen ? "-rotate-45 translate-x-0.5" : ""
					)}></span>
				</div>
			</button>
		</div>
		
		<!-- Logo -->
		<a href="/" class="flex items-center space-x-2 mr-4 md:mr-6 md:ml-0 -ml-3">
			<span class="text-xl md:text-2xl font-black text-primary hover:text-primary/90 transition-colors tracking-tighter bg-gradient-to-r from-orange-500 to-orange-600 bg-clip-text text-transparent hover:from-orange-600 hover:to-orange-700 drop-shadow-sm">Driplo</span>
		</a>

		<!-- Desktop Search Bar -->
		<div class="flex-1 max-w-2xl mx-2 md:mx-4 hidden md:block">
			<div class="relative">
				<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
				<input
					type="search"
					placeholder={m.header_search_placeholder()}
					bind:value={searchQuery}
					onkeydown={(e) => e.key === 'Enter' && handleSearch()}
					class="w-full rounded-xl border border-input bg-background pl-10 pr-4 py-2.5 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2 transition-all hover:border-orange-200"
				/>
			</div>
		</div>

		<!-- Desktop Actions -->
		<div class="hidden md:flex items-center space-x-2">
			<LanguageSwitcher />
			<button class="relative p-2 hover:bg-muted rounded-lg transition-colors">
				<Heart class="h-5 w-5 text-muted-foreground hover:text-foreground" />
				<span class="sr-only">{m.header_favorites()}</span>
			</button>
			<a href="/messages" class="relative p-2 hover:bg-muted rounded-lg transition-colors">
				<MessageCircle class="h-5 w-5 text-muted-foreground hover:text-foreground" />
				<span class="sr-only">{m.header_messages()}</span>
			</a>
			<a href={$user ? ($profile?.username ? `/profile/${$profile.username}` : '/profile') : '/login'} class="relative hover:bg-orange-50 rounded-full transition-colors group">
				{#if $user}
					{#if $profile?.avatar_url}
						<img src={$profile.avatar_url} alt="Profile" class="h-9 w-9 rounded-full border-2 border-orange-200 group-hover:border-orange-300 transition-colors object-cover" />
					{:else}
						<div class="h-9 w-9 rounded-full bg-gradient-to-br from-orange-400 via-orange-500 to-orange-600 flex items-center justify-center shadow-md border border-orange-300 group-hover:shadow-lg transition-all">
							<span class="text-white font-semibold text-sm">{($profile?.full_name || $profile?.username || $user.email)?.charAt(0).toUpperCase()}</span>
						</div>
					{/if}
				{:else}
					<div class="h-9 w-9 rounded-full border-2 border-orange-200 hover:border-orange-400 bg-white flex items-center justify-center group-hover:bg-orange-50 transition-all shadow-sm hover:shadow-md">
						<User class="h-5 w-5 text-orange-600" />
					</div>
				{/if}
				<span class="sr-only">{$user ? m.header_my_profile() : m.header_sign_in()}</span>
			</a>
		</div>

		<!-- Mobile Actions -->
		<div class="flex md:hidden items-center gap-1 ml-auto">
			<a href="/cart" class="relative p-2.5 hover:bg-gray-50 rounded-xl transition-all duration-200 group">
				<ShoppingBag class="h-5 w-5 text-gray-600 group-hover:text-orange-600 transition-colors" />
				<span class="sr-only">{m.header_my_cart()}</span>
				<!-- Cart Badge -->
				<div class="absolute -top-0.5 -right-0.5 h-5 w-5 bg-orange-500 rounded-full flex items-center justify-center shadow-sm">
					<span class="text-[10px] text-white font-semibold">0</span>
				</div>
			</a>
			<a href={$user ? ($profile?.username ? `/profile/${$profile.username}` : '/profile') : '/login'} class="relative p-1 hover:bg-gray-50 rounded-xl transition-all duration-200 group">
				{#if $user}
					{#if $profile?.avatar_url}
						<img src={$profile.avatar_url} alt="Profile" class="h-8 w-8 rounded-xl border-2 border-gray-200 group-hover:border-orange-300 transition-all object-cover" />
					{:else}
						<div class="h-8 w-8 rounded-xl bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-sm group-hover:shadow-md transition-all">
							<span class="text-white font-semibold text-xs">{($profile?.full_name || $profile?.username || $user.email)?.charAt(0).toUpperCase()}</span>
						</div>
					{/if}
				{:else}
					<div class="h-8 w-8 rounded-xl border-2 border-gray-200 hover:border-orange-300 bg-white flex items-center justify-center group-hover:bg-orange-50 transition-all">
						<User class="h-4 w-4 text-gray-600 group-hover:text-orange-600 transition-colors" />
					</div>
				{/if}
				<span class="sr-only">{$user ? m.header_my_profile() : m.header_sign_in()}</span>
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
			class="fixed inset-0 z-[99] bg-black/40 backdrop-blur-sm animate-fade-in" 
			onclick={closeMenu}
			aria-label="Close menu"
		></button>
		
		<!-- Slide-out Panel -->
		<div class="fixed top-0 left-0 bottom-0 z-[100] w-80 max-w-[85vw] bg-white shadow-2xl animate-slide-in-left">
			<div class="flex h-full flex-col">
				<!-- Header -->
				<div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
					<div class="flex items-center gap-3">
						<div class="h-10 w-10 rounded-xl bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-sm">
							<span class="text-white font-bold text-lg">D</span>
						</div>
						<h2 class="text-lg font-semibold text-gray-900">{m.header_menu()}</h2>
					</div>
					<button 
						onclick={closeMenu}
						class="h-9 w-9 flex items-center justify-center rounded-xl hover:bg-gray-50 transition-all duration-200 group"
						aria-label="Close menu"
					>
						<X class="h-5 w-5 text-gray-400 group-hover:text-gray-600 transition-colors" />
					</button>
				</div>

				<!-- Navigation -->
				<nav class="flex-1 overflow-y-auto px-4 py-4">
					<div class="space-y-1">
						<a 
							href="/" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 hover:text-gray-900 group"
						>
							<div class="h-8 w-8 rounded-lg bg-gray-100 flex items-center justify-center group-hover:bg-orange-100 transition-colors">
								<Home class="h-4 w-4 text-gray-600 group-hover:text-orange-600 transition-colors" />
							</div>
							{m.header_home()}
						</a>
						<a 
							href="/browse" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 hover:text-gray-900 group"
						>
							<div class="h-8 w-8 rounded-lg bg-gray-100 flex items-center justify-center group-hover:bg-orange-100 transition-colors">
								<Search class="h-4 w-4 text-gray-600 group-hover:text-orange-600 transition-colors" />
							</div>
							{m.header_browse()}
						</a>
						<a 
							href="/sell" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-white bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 transition-all duration-200 shadow-sm hover:shadow-md"
						>
							<div class="h-8 w-8 rounded-lg bg-white/20 flex items-center justify-center">
								<Camera class="h-4 w-4 text-white" />
							</div>
							{m.header_sell_item()}
						</a>
						<a 
							href="/messages" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 hover:text-gray-900 group"
						>
							<div class="h-8 w-8 rounded-lg bg-gray-100 flex items-center justify-center group-hover:bg-orange-100 transition-colors">
								<MessageCircle class="h-4 w-4 text-gray-600 group-hover:text-orange-600 transition-colors" />
							</div>
							{m.header_messages()}
						</a>
						<a 
							href="/wishlist" 
							onclick={closeMenu}
							class="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 hover:text-gray-900 group"
						>
							<div class="h-8 w-8 rounded-lg bg-gray-100 flex items-center justify-center group-hover:bg-orange-100 transition-colors">
								<Heart class="h-4 w-4 text-gray-600 group-hover:text-orange-600 transition-colors" />
							</div>
							{m.header_favorites()}
						</a>
					</div>
					
					<!-- Profile Section -->
					{#if $user}
						<div class="mt-6 pt-6 border-t border-gray-100">
							<div class="px-4 mb-4">
								<a 
									href={$profile?.username ? `/profile/${$profile.username}` : '/profile'}
									onclick={closeMenu}
									class="flex items-center gap-3 p-3 rounded-xl bg-gray-50 hover:bg-gray-100 transition-all duration-200"
								>
									{#if $profile?.avatar_url}
										<img src={$profile.avatar_url} alt="Profile" class="h-12 w-12 rounded-xl object-cover" />
									{:else}
										<div class="h-12 w-12 rounded-xl bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center">
											<span class="text-white font-semibold text-lg">{($profile?.full_name || $profile?.username || $user.email)?.charAt(0).toUpperCase()}</span>
										</div>
									{/if}
									<div class="flex-1">
										<p class="text-sm font-semibold text-gray-900">{$profile?.full_name || $profile?.username || 'My Profile'}</p>
										<p class="text-xs text-gray-500">View profile</p>
									</div>
								</a>
							</div>
							<div class="space-y-1">
								<a 
									href="/profile/settings" 
									onclick={closeMenu}
									class="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 hover:text-gray-900 group"
								>
									<div class="h-8 w-8 rounded-lg bg-gray-100 flex items-center justify-center group-hover:bg-orange-100 transition-colors">
										<User class="h-4 w-4 text-gray-600 group-hover:text-orange-600 transition-colors" />
									</div>
									{m.header_settings()}
								</a>
							</div>
						</div>
					{:else}
						<div class="mt-6 pt-6 border-t border-gray-100 px-4">
							<a 
								href="/login"
								onclick={closeMenu}
								class="flex items-center justify-center gap-2 w-full py-3 px-4 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium transition-all duration-200"
							>
								<User class="h-4 w-4" />
								{m.header_sign_in()}
							</a>
						</div>
					{/if}
					
					<!-- Categories Section -->
					{#if categories.length > 0}
						<div class="mt-6 pt-6 border-t border-gray-100">
							<h3 class="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">{m.header_categories()}</h3>
							<div class="space-y-1">
								{#each categories as category}
									<a 
										href="/{category.slug}"
										onclick={closeMenu}
										class="flex items-center gap-3 rounded-xl px-4 py-2.5 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-gray-50 hover:text-gray-900"
									>
										<span class="text-lg">{category.icon || '📦'}</span>
										{category.name}
									</a>
								{/each}
							</div>
						</div>
					{/if}
				</nav>

				<!-- Footer -->
				<div class="border-t border-gray-100 px-4 py-4 space-y-3">
					<!-- Language Switcher -->
					<div class="flex items-center justify-between px-2">
						<span class="text-xs text-gray-500 font-medium">Language</span>
						<LanguageSwitcher />
					</div>
					
					{#if $user}
						<button 
							onclick={() => {auth.signOut(); closeMenu();}}
							class="w-full py-2.5 px-4 rounded-xl text-sm font-medium text-gray-600 hover:text-red-600 hover:bg-red-50 transition-all duration-200 flex items-center justify-center gap-2"
						>
							<LogOut class="h-4 w-4" />
							Sign out
						</button>
					{/if}
				</div>
			</div>
		</div>
	{/if}
</header>

<style>
	@keyframes fade-in {
		from {
			opacity: 0;
		}
		to {
			opacity: 1;
		}
	}
	
	@keyframes slide-in-left {
		from {
			transform: translateX(-100%);
		}
		to {
			transform: translateX(0);
		}
	}
	
	.animate-fade-in {
		animation: fade-in 0.2s ease-out;
	}
	
	.animate-slide-in-left {
		animation: slide-in-left 0.3s ease-out;
	}
</style>