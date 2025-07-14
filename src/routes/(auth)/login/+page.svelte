<script lang="ts">
	import { enhance } from '$app/forms'
	import { goto } from '$app/navigation'
	import { auth } from '$lib/stores/auth'
	import { Button } from '$lib/components/ui'
	import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card'
	import { Input } from '$lib/components/ui'
	import { Eye, EyeOff, Github, Mail } from 'lucide-svelte'
	import { toast } from 'svelte-sonner'

	let email = ''
	let password = ''
	let showPassword = false
	let loading = false

	async function handleLogin() {
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
			toast.error(error.message || 'Login failed')
		} finally {
			loading = false
		}
	}

	async function handleOAuth(provider: 'google' | 'github') {
		loading = true
		try {
			await auth.signInWithProvider(provider)
		} catch (error: any) {
			toast.error(error.message || 'OAuth login failed')
			loading = false
		}
	}
</script>

<svelte:head>
	<title>Login | Threadly</title>
	<meta name="description" content="Sign in to your Threadly account" />
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-50 px-4">
	<div class="w-full max-w-md">
		<Card>
			<CardHeader class="text-center">
				<CardTitle class="text-2xl font-bold text-gray-900">Welcome back</CardTitle>
				<p class="text-gray-600">Sign in to your account</p>
			</CardHeader>
			<CardContent class="space-y-4">
				<!-- OAuth Buttons -->
				<div class="space-y-3">
					<Button
						variant="outline"
						class="w-full"
						onclick={() => handleOAuth('google')}
						disabled={loading}
					>
						<Mail class="w-4 h-4 mr-2" />
						Continue with Google
					</Button>
					<Button
						variant="outline"
						class="w-full"
						onclick={() => handleOAuth('github')}
						disabled={loading}
					>
						<Github class="w-4 h-4 mr-2" />
						Continue with GitHub
					</Button>
				</div>

				<!-- Divider -->
				<div class="relative">
					<div class="absolute inset-0 flex items-center">
						<div class="w-full border-t border-gray-300"></div>
					</div>
					<div class="relative flex justify-center text-sm">
						<span class="px-2 bg-white text-gray-500">Or continue with email</span>
					</div>
				</div>

				<!-- Login Form -->
				<form onsubmit={(e) => { e.preventDefault(); handleLogin(); }} class="space-y-4">
					<div>
						<label for="email" class="block text-sm font-medium text-gray-700 mb-1">
							Email address
						</label>
						<Input
							id="email"
							type="email"
							bind:value={email}
							placeholder="Enter your email"
							required
							disabled={loading}
							class="w-full"
						/>
					</div>

					<div>
						<label for="password" class="block text-sm font-medium text-gray-700 mb-1">
							Password
						</label>
						<div class="relative">
							<Input
								id="password"
								type={showPassword ? 'text' : 'password'}
								bind:value={password}
								placeholder="Enter your password"
								required
								disabled={loading}
								class="w-full pr-10"
							/>
							<button
								type="button"
								class="absolute inset-y-0 right-0 pr-3 flex items-center"
								onclick={() => showPassword = !showPassword}
							>
								{#if showPassword}
									<EyeOff class="h-4 w-4 text-gray-400" />
								{:else}
									<Eye class="h-4 w-4 text-gray-400" />
								{/if}
							</button>
						</div>
					</div>

					<div class="flex items-center justify-between">
						<label class="flex items-center">
							<input type="checkbox" class="rounded border-gray-300 text-orange-600 focus:ring-orange-500" />
							<span class="ml-2 text-sm text-gray-600">Remember me</span>
						</label>
						<a href="/auth/forgot-password" class="text-sm text-orange-600 hover:text-orange-500">
							Forgot password?
						</a>
					</div>

					<Button type="submit" class="w-full" disabled={loading}>
						{loading ? 'Signing in...' : 'Sign in'}
					</Button>
				</form>

				<!-- Sign up link -->
				<div class="text-center">
					<p class="text-sm text-gray-600">
						Don't have an account?
						<a href="/register" class="font-medium text-orange-600 hover:text-orange-500">
							Sign up
						</a>
					</p>
				</div>
			</CardContent>
		</Card>
	</div>
</div>