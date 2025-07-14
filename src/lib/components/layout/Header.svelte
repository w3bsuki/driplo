<script lang="ts">
	import { Search, Heart, MessageCircle, User, Menu, Camera, Home, ShoppingBag, Instagram, Twitter, Facebook, X as XIcon } from 'lucide-svelte';
	import { Button } from '$lib/components/ui';
	import * as Sheet from '$lib/components/ui/sheet';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import { user, profile } from '$lib/stores/auth';
	import type { Category } from '$lib/types';
	import { page } from '$app/stores';
	import * as m from '$lib/paraglide/messages.js';
	
	interface Props {
		categories?: Category[];
	}
	
	let { categories = [] }: Props = $props();
	
	let isMenuOpen = $state(false);
	let searchQuery = $state('');
	let activeCategory = $state('');
	let showBanner = $state(true);

	// Navigation items for mobile menu
	const navigationItems = [
		{ href: '/', icon: Home, label: m.header_home(), description: m.navigation_home_desc() },
		{ href: '/browse', icon: Search, label: m.header_browse(), description: m.navigation_browse_desc() },
		{ href: '/sell', icon: Camera, label: m.header_sell_item(), description: m.navigation_sell_desc(), highlight: true },
		{ href: '/cart', icon: ShoppingBag, label: m.header_my_cart(), description: m.navigation_cart_desc(), authRequired: true },
		{ href: '/messages', icon: MessageCircle, label: m.header_messages(), description: m.navigation_messages_desc() },
		{ href: '/favorites', icon: Heart, label: m.header_favorites(), description: m.navigation_favorites_desc() }
	];
	
	// Enhanced category icons
	const categoryIcons: Record<string, string> = {
		women: '👗',
		men: '👔', 
		kids: '🧸',
		designer: '💎',
		shoes: '👟',
		bags: '👜',
		accessories: '⌚',
		sports: '⚽',
		vintage: '🎭'
	};

	const quickCategories = $derived([
		{ name: m.categories_all(), value: '', slug: '', icon: '🔍' },
		...categories.map(cat => ({ 
			name: cat.name, 
			value: cat.slug, 
			slug: cat.slug,
			icon: categoryIcons[cat.slug] || cat.icon || '📦'
		}))
	]);

	// Check if current page is active
	function isActiveRoute(href: string): boolean {
		return $page.url.pathname === href;
	}

	// Get user profile link
	function getUserProfileLink(): string {
		if ($user && $profile?.username) {
			return `/profile/${$profile.username}`;
		}
		return $user ? '/profile' : '/login';
	}

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
			goto(`/${category}`);
		} else {
			goto('/browse');
		}
	}

	function handleMenuClose() {
		isMenuOpen = false;
	}

	function handleNavigation(href: string) {
		goto(href);
		isMenuOpen = false;
	}
</script>

<!-- Donation Banner -->
{#if showBanner}
	<div class="bg-gradient-to-r from-green-600 to-emerald-600 text-white py-2 px-4 text-center relative">
		<div class="container mx-auto flex items-center justify-center gap-2 text-sm">
			<span class="font-medium">🌱 {m.banner_donate_title()}</span>
			<span class="hidden sm:inline">{m.banner_donate_subtitle()}</span>
			<a 
				href="/donate" 
				class="inline-flex items-center gap-1 bg-white/20 hover:bg-white/30 px-3 py-1 rounded-full text-xs font-medium transition-colors"
			>
				{m.banner_learn_more()}
				<svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
				</svg>
			</a>
			<button 
				onclick={() => showBanner = false}
				class="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-white/20 rounded transition-colors"
				aria-label={m.banner_close()}
			>
				<XIcon class="h-4 w-4" />
			</button>
		</div>
	</div>
{/if}

<header class="sticky top-0 z-50 w-full border-b bg-white">
	<!-- Main Header -->
	<div class="container flex h-16 items-center px-4">
		<!-- Clean Mobile Navbar -->
		<div class="flex md:hidden items-center w-full">
			<!-- Left: Mobile Menu & Logo -->
			<div class="flex items-center">
				<Sheet.Root bind:open={isMenuOpen}>
					<Sheet.Trigger 
						class="inline-flex items-center justify-center h-10 w-10 hover:bg-orange-50 rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2"
					>
						<Menu class="h-5 w-5 text-orange-600" />
						<span class="sr-only">Toggle menu</span>
					</Sheet.Trigger>
				
				<!-- Mobile Menu Sheet Content -->
				<Sheet.Content side="left" class="w-80 max-w-[85vw] p-0 bg-white border-r border-gray-200 shadow-xl" style="z-index: 9999;">
					<div class="flex h-full flex-col bg-gradient-to-b from-white to-gray-50">
						<!-- Header -->
						<Sheet.Header class="px-6 py-4 border-b border-gray-200 bg-white shadow-sm">
							<div class="flex items-center justify-between">
								<div class="flex items-center gap-3">
									<div class="h-10 w-10 rounded-lg bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-md">
										<span class="text-white font-black text-lg">D</span>
									</div>
									<Sheet.Title class="text-xl font-black text-gray-900">Driplo</Sheet.Title>
								</div>
							</div>
						</Sheet.Header>

						<!-- Navigation -->
						<nav class="flex-1 overflow-y-auto px-4 py-5">
							<div class="space-y-1.5">
								{#each navigationItems as item}
									{@const IconComponent = item.icon}
									{#if !item.authRequired || $user}
										<a 
											href={item.href}
											onclick={() => handleNavigation(item.href)}
											class={cn(
												"flex items-center gap-3 rounded-xl px-3 py-2.5 transition-all duration-200 group border",
												item.highlight
													? "bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-md hover:shadow-lg hover:from-orange-600 hover:to-orange-700 border-orange-600"
													: isActiveRoute(item.href)
														? "bg-white text-gray-900 border-orange-200 shadow-sm"
														: "text-gray-700 hover:bg-white hover:text-gray-900 border-transparent hover:border-gray-200 hover:shadow-sm"
											)}
										>
											<div class={cn(
												"flex items-center justify-center w-8 h-8 rounded-lg transition-colors",
												item.highlight
													? "bg-white/20"
													: isActiveRoute(item.href)
														? "bg-orange-100"
														: "bg-gray-100 group-hover:bg-orange-50"
											)}>
												<IconComponent class={cn(
													"h-4 w-4",
													item.highlight ? "text-white" : isActiveRoute(item.href) ? "text-orange-600" : "text-gray-600 group-hover:text-orange-600"
												)} />
											</div>
											<div class="flex-1">
												<div class={cn(
													"font-medium text-sm",
													item.highlight ? "text-white" : ""
												)}>{item.label}</div>
												<div class={cn(
													"text-xs",
													item.highlight ? "text-white/80" : "text-gray-500"
												)}>{item.description}</div>
											</div>
											{#if item.href === '/cart' && $user}
												<span class="bg-orange-500 text-white text-xs font-bold px-2 py-1 rounded-full">2</span>
											{/if}
										</a>
									{/if}
								{/each}
								
								<!-- Profile/Login -->
								<div class="pt-3 mt-3 border-t border-gray-200">
									<a 
										href={getUserProfileLink()}
										onclick={() => handleNavigation(getUserProfileLink())}
										class="flex items-center gap-3 rounded-xl px-3 py-2.5 transition-all duration-200 bg-white hover:bg-gray-50 border border-gray-200 hover:border-orange-200 shadow-sm hover:shadow-md"
									>
										<div class="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-orange-400 to-orange-600 shadow-sm">
											<User class="h-4 w-4 text-white" />
										</div>
										<div class="flex-1">
											<div class="font-medium text-sm text-gray-900">
												{$user ? m.header_my_profile() : m.header_sign_in()}
											</div>
											<div class="text-xs text-gray-500">
												{$user ? m.navigation_profile_desc() : m.navigation_login_desc()}
											</div>
										</div>
									</a>
								</div>
							</div>
							
							<!-- Categories Section -->
							{#if categories.length > 0}
								<div class="mt-5 pt-5 border-t border-gray-200">
									<h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">{m.header_categories()}</h3>
									<div class="space-y-1">
										{#each categories as category}
											<a 
												href="/{category.slug}"
												onclick={() => handleNavigation(`/${category.slug}`)}
												class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-700 transition-all duration-200 hover:bg-white hover:text-gray-900 border border-transparent hover:border-gray-200 hover:shadow-sm group"
											>
												<span class="text-lg group-hover:scale-110 transition-transform duration-200">{categoryIcons[category.slug] || category.icon || '📦'}</span>
												{category.name}
											</a>
										{/each}
									</div>
								</div>
							{/if}
							
							<!-- Settings -->
							{#if $user}
								<div class="mt-5 space-y-1">
									<a 
										href="/profile/settings"
										onclick={() => handleNavigation('/profile/settings')}
										class="flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium text-orange-600 transition-all duration-200 hover:bg-white hover:text-orange-700 border border-transparent hover:border-orange-200 hover:shadow-sm"
									>
										<User class="h-4 w-4 text-orange-600" />
										{m.header_settings()}
									</a>
								</div>
							{/if}
						</nav>

						<!-- Footer -->
						<div class="border-t border-gray-200">
							<!-- Brand & Legal -->
							<div class="px-4 py-4">
								<div class="text-center space-y-2">
									<p class="text-xs text-gray-500">
										{m.footer_made_with_love()}
									</p>
									<div class="flex items-center justify-center gap-3 text-xs">
										<a href="/privacy" class="text-gray-500 hover:text-orange-600 transition-colors">{m.footer_privacy()}</a>
										<span class="text-gray-300">•</span>
										<a href="/terms" class="text-gray-500 hover:text-orange-600 transition-colors">{m.footer_terms()}</a>
										<span class="text-gray-300">•</span>
										<a href="/gdpr" class="text-gray-500 hover:text-orange-600 transition-colors">{m.footer_gdpr()}</a>
									</div>
								</div>
							</div>
							
							<!-- Social Media Links -->
							<div class="px-4 pb-4">
								<p class="text-xs text-gray-500 text-center mb-3">{m.footer_follow_us()}</p>
								<div class="flex items-center justify-center gap-2">
									<a 
										href="https://instagram.com/driplo" 
										target="_blank" 
										rel="noopener noreferrer"
										class="w-9 h-9 rounded-lg bg-gray-100 hover:bg-gradient-to-br hover:from-purple-500 hover:to-pink-500 flex items-center justify-center transition-all duration-200 group"
										aria-label="Instagram"
									>
										<Instagram class="h-4 w-4 text-gray-600 group-hover:text-white" />
									</a>
									<a 
										href="https://twitter.com/driplo" 
										target="_blank" 
										rel="noopener noreferrer"
										class="w-9 h-9 rounded-lg bg-gray-100 hover:bg-black flex items-center justify-center transition-all duration-200 group"
										aria-label="X (Twitter)"
									>
										<XIcon class="h-4 w-4 text-gray-600 group-hover:text-white" />
									</a>
									<a 
										href="https://facebook.com/driplo" 
										target="_blank" 
										rel="noopener noreferrer"
										class="w-9 h-9 rounded-lg bg-gray-100 hover:bg-blue-600 flex items-center justify-center transition-all duration-200 group"
										aria-label="Facebook"
									>
										<Facebook class="h-4 w-4 text-gray-600 group-hover:text-white" />
									</a>
								</div>
							</div>
						</div>
					</div>
				</Sheet.Content>
				</Sheet.Root>
				
				<!-- Logo -->
				<a href="/" class="inline-flex items-center pl-0 pr-2 py-2 hover:bg-orange-50 rounded-lg transition-colors">
					<span class="text-2xl font-black text-gray-900 hover:text-orange-600 transition-colors tracking-tighter">Driplo</span>
				</a>
			</div>
			
			<!-- Spacer to push right content to the edge -->
			<div class="flex-1"></div>
			
			<!-- Right: Mobile Actions -->
			<div class="flex items-center gap-2">
				<!-- Messages Button -->
				<a 
					href="/messages"
					class="inline-flex items-center justify-center h-10 w-10 hover:bg-orange-50 rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2"
					aria-label="Messages"
				>
					<MessageCircle class="h-5 w-5 text-orange-600" />
				</a>
				
				<!-- Account Button -->
				<a 
					href={getUserProfileLink()}
					class="inline-flex items-center justify-center h-10 w-10 hover:bg-orange-50 rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2"
					aria-label={$user ? 'Profile' : 'Sign in'}
				>
					<div class="h-8 w-8 rounded-lg bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-sm">
						<User class="h-5 w-5 text-white" />
					</div>
				</a>
			</div>
		</div>
		
		<!-- Desktop Logo (Hidden on Mobile) -->
		<a href="/" class="hidden md:flex items-center space-x-2 mr-4 md:mr-6">
			<span class="text-2xl font-black text-gray-900 hover:text-orange-600 transition-colors tracking-tighter">Driplo</span>
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
			<button class="relative p-2 hover:bg-muted rounded-lg transition-colors">
				<Heart class="h-5 w-5 text-muted-foreground hover:text-foreground" />
				<span class="sr-only">{m.header_favorites()}</span>
			</button>
			<a href="/messages" class="relative p-2 hover:bg-muted rounded-lg transition-colors">
				<MessageCircle class="h-5 w-5 text-muted-foreground hover:text-foreground" />
				<span class="sr-only">{m.header_messages()}</span>
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
				<span class="sr-only">{$user ? m.header_my_profile() : m.header_sign_in()}</span>
			</a>
		</div>
	</div>


	<!-- Category Filter Chips (Desktop) -->
	<div class="hidden md:block border-t bg-gradient-to-r from-gray-50 to-white">
		<div class="container px-4 py-4">
			<div class="flex items-center gap-3 overflow-x-auto scrollbar-hide">
				{#each quickCategories as category}
					<button
						onclick={() => selectCategory(category.value)}
						class={cn(
							"group relative whitespace-nowrap rounded-full px-5 py-2.5 text-sm font-semibold transition-all duration-300 border-2 flex items-center gap-2 hover:scale-105",
							activeCategory === category.value
								? "bg-gradient-to-r from-orange-500 to-orange-600 text-white border-orange-600 shadow-lg hover:shadow-xl hover:from-orange-600 hover:to-orange-700"
								: "bg-white hover:bg-gray-50 text-gray-700 hover:text-gray-900 border-gray-200 hover:border-orange-200 shadow-sm hover:shadow-md"
						)}
					>
						<span class={cn(
							"text-base transition-transform duration-300 group-hover:scale-110",
							activeCategory === category.value ? "filter drop-shadow-sm" : ""
						)}>
							{category.icon}
						</span>
						<span class="select-none">{category.name}</span>
						
						<!-- Active indicator -->
						{#if activeCategory === category.value}
							<div class="absolute -bottom-1 left-1/2 transform -translate-x-1/2 w-2 h-2 bg-orange-500 rounded-full shadow-sm"></div>
						{/if}
					</button>
				{/each}
			</div>
		</div>
	</div>

</header>

<style>
	/* Hide scrollbar for category chips */
	.scrollbar-hide {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	.scrollbar-hide::-webkit-scrollbar {
		display: none;
	}
</style>