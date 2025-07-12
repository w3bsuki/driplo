<script lang="ts">
	import { Search, Heart, MessageCircle, User, Menu, X } from 'lucide-svelte';
	import { Button } from '$lib/components/ui';
	import { cn } from '$lib/utils';
	
	let mobileMenuOpen = $state(false);
	let searchQuery = $state('');
</script>

<header class="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
	<div class="container flex h-16 items-center px-4">
		<!-- Logo -->
		<a href="/" class="flex items-center space-x-2 mr-4">
			<span class="text-2xl font-bold text-primary">Threadly</span>
		</a>

		<!-- Desktop Navigation -->
		<nav class="hidden md:flex items-center space-x-6 text-sm font-medium">
			<a href="/browse?category=women" class="transition-colors hover:text-primary">Women</a>
			<a href="/browse?category=men" class="transition-colors hover:text-primary">Men</a>
			<a href="/browse?category=kids" class="transition-colors hover:text-primary">Kids</a>
			<a href="/browse?category=designer" class="transition-colors hover:text-primary">Designer</a>
			<a href="/browse?category=home" class="transition-colors hover:text-primary">Home</a>
		</nav>

		<!-- Search Bar -->
		<div class="flex-1 max-w-xl mx-4 hidden md:block">
			<div class="relative">
				<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
				<input
					type="search"
					placeholder="Search for items..."
					bind:value={searchQuery}
					class="w-full rounded-md border border-input bg-background pl-10 pr-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
				/>
			</div>
		</div>

		<!-- Desktop Actions -->
		<div class="hidden md:flex items-center space-x-4">
			<Button onclick={() => window.location.href='/sell'} size="sm">
				Sell now
			</Button>
			<button class="relative">
				<Heart class="h-5 w-5" />
				<span class="sr-only">Favorites</span>
			</button>
			<a href="/messages" class="relative">
				<MessageCircle class="h-5 w-5" />
				<span class="sr-only">Messages</span>
			</a>
			<a href="/profile" class="relative">
				<User class="h-5 w-5" />
				<span class="sr-only">Profile</span>
			</a>
		</div>

		<!-- Mobile Menu Button -->
		<button
			onclick={() => mobileMenuOpen = !mobileMenuOpen}
			class="md:hidden"
		>
			{#if mobileMenuOpen}
				<X class="h-6 w-6" />
			{:else}
				<Menu class="h-6 w-6" />
			{/if}
			<span class="sr-only">Toggle menu</span>
		</button>
	</div>

	<!-- Mobile Menu -->
	{#if mobileMenuOpen}
		<div class="md:hidden border-t">
			<div class="space-y-1 px-4 pb-3 pt-2">
				<div class="relative mb-3">
					<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
					<input
						type="search"
						placeholder="Search for items..."
						bind:value={searchQuery}
						class="w-full rounded-md border border-input bg-background pl-10 pr-3 py-2 text-sm"
					/>
				</div>
				<a href="/browse?category=women" class="block px-3 py-2 text-base font-medium">Women</a>
				<a href="/browse?category=men" class="block px-3 py-2 text-base font-medium">Men</a>
				<a href="/browse?category=kids" class="block px-3 py-2 text-base font-medium">Kids</a>
				<a href="/browse?category=designer" class="block px-3 py-2 text-base font-medium">Designer</a>
				<a href="/browse?category=home" class="block px-3 py-2 text-base font-medium">Home</a>
				<div class="border-t pt-2 mt-2">
					<Button onclick={() => window.location.href='/sell'} class="w-full mb-2">
						Sell now
					</Button>
					<div class="flex justify-around py-2">
						<a href="/favorites" class="flex flex-col items-center">
							<Heart class="h-5 w-5 mb-1" />
							<span class="text-xs">Favorites</span>
						</a>
						<a href="/messages" class="flex flex-col items-center">
							<MessageCircle class="h-5 w-5 mb-1" />
							<span class="text-xs">Messages</span>
						</a>
						<a href="/profile" class="flex flex-col items-center">
							<User class="h-5 w-5 mb-1" />
							<span class="text-xs">Profile</span>
						</a>
					</div>
				</div>
			</div>
		</div>
	{/if}
</header>