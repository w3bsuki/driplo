<script lang="ts">
	import { auth } from '$lib/stores/auth'
	import { goto } from '$app/navigation'
	import { onMount } from 'svelte'
	import { Button } from '$lib/components/ui'
	import { Input } from '$lib/components/ui'
	import { toast } from 'svelte-sonner'

	let email = $state('')
	let password = $state('')
	let loading = $state(false)

	onMount(() => {
		// Redirect if already logged in
		const unsubscribe = auth.user.subscribe(user => {
			if (user) {
				goto('/')
				unsubscribe()
			}
		})

		return unsubscribe
	})

	async function handleLogin(e: Event) {
		e.preventDefault()
		
		if (!email || !password) {
			toast.error('Please fill in all fields')
			return
		}

		loading = true
		
		try {
			await auth.signIn(email, password)
			toast.success('Welcome back!')
			goto('/')
		} catch (error: any) {
			console.error('Login error:', error)
			toast.error(error.message || 'Login failed')
		} finally {
			loading = false
		}
	}

	async function handleGoogleLogin() {
		try {
			await auth.signInWithProvider('google')
		} catch (error: any) {
			console.error('Google login error:', error)
			toast.error(error.message || 'Google login failed')
		}
	}
</script>

<svelte:head>
	<title>Login | Threadly</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
	<div class="max-w-md w-full space-y-8">
		<div>
			<h2 class="mt-6 text-center text-3xl font-bold text-gray-900">
				Sign in to your account
			</h2>
			<p class="mt-2 text-center text-sm text-gray-600">
				Or{' '}
				<a href="/auth/register" class="font-medium text-orange-600 hover:text-orange-500">
					create a new account
				</a>
			</p>
		</div>
		
		<form class="mt-8 space-y-6" on:submit={handleLogin}>
			<div class="space-y-4">
				<div>
					<label for="email" class="block text-sm font-medium text-gray-700">
						Email address
					</label>
					<Input
						id="email"
						type="email"
						required
						bind:value={email}
						placeholder="Enter your email"
						class="mt-1"
					/>
				</div>
				
				<div>
					<label for="password" class="block text-sm font-medium text-gray-700">
						Password
					</label>
					<Input
						id="password"
						type="password"
						required
						bind:value={password}
						placeholder="Enter your password"
						class="mt-1"
					/>
				</div>
			</div>

			<div class="flex items-center justify-between">
				<div class="text-sm">
					<a href="/auth/forgot-password" class="font-medium text-orange-600 hover:text-orange-500">
						Forgot your password?
					</a>
				</div>
			</div>

			<div class="space-y-3">
				<Button
					type="submit"
					class="w-full bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
					disabled={loading}
				>
					{loading ? 'Signing in...' : 'Sign in'}
				</Button>

				<div class="relative">
					<div class="absolute inset-0 flex items-center">
						<div class="w-full border-t border-gray-300" />
					</div>
					<div class="relative flex justify-center text-sm">
						<span class="px-2 bg-gray-50 text-gray-500">Or continue with</span>
					</div>
				</div>

				<Button
					type="button"
					variant="outline"
					class="w-full"
					on:click={handleGoogleLogin}
				>
					<svg class="w-5 h-5 mr-2" viewBox="0 0 24 24">
						<path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
						<path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
						<path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
						<path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
					</svg>
					Continue with Google
				</Button>
			</div>
		</form>
	</div>
</div>