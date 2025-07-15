<script lang="ts">
	import { goto } from '$app/navigation'
	import { auth } from '$lib/stores/auth'
	import { Button } from '$lib/components/ui'
	import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card'
	import { Input } from '$lib/components/ui'
	import { Eye, EyeOff, Github, Mail } from 'lucide-svelte'
	import { toast } from 'svelte-sonner'
	import { z } from 'zod'

	let email = ''
	let password = ''
	let confirmPassword = ''
	let username = ''
	let fullName = ''
	let showPassword = false
	let showConfirmPassword = false
	let loading = false
	let agreedToTerms = false

	const registerSchema = z.object({
		email: z.string().email('Please enter a valid email address'),
		password: z.string().min(8, 'Password must be at least 8 characters'),
		confirmPassword: z.string(),
		username: z.string()
			.min(3, 'Username must be at least 3 characters')
			.max(30, 'Username must be less than 30 characters')
			.regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),
		fullName: z.string().optional(),
		agreedToTerms: z.boolean().refine(val => val === true, 'You must agree to the terms of service')
	}).refine(data => data.password === data.confirmPassword, {
		message: "Passwords don't match",
		path: ["confirmPassword"]
	})

	async function handleRegister() {
		try {
			const validatedData = registerSchema.parse({
				email,
				password,
				confirmPassword,
				username,
				fullName: fullName || undefined,
				agreedToTerms
			})

			loading = true
			await auth.signUp(email, password, username, fullName || undefined)
			toast.success('Account created! Please check your email to verify your account.')
			goto('/login')
		} catch (error: any) {
			if (error.issues) {
				// Zod validation errors
				error.issues.forEach((issue: any) => {
					toast.error(issue.message)
				})
			} else {
				toast.error(error.message || 'Registration failed')
			}
		} finally {
			loading = false
		}
	}

	async function handleOAuth(provider: 'google' | 'github') {
		loading = true
		try {
			await auth.signInWithProvider(provider)
		} catch (error: any) {
			toast.error(error.message || 'OAuth registration failed')
			loading = false
		}
	}
</script>

<svelte:head>
	<title>Sign Up | Threadly</title>
	<meta name="description" content="Create your Threadly account" />
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-50 px-4 py-8">
	<div class="w-full max-w-md">
		<Card>
			<CardHeader class="text-center">
				<CardTitle class="text-2xl font-bold text-gray-900">Create account</CardTitle>
				<p class="text-gray-600">Join Threadly today</p>
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

				<!-- Registration Form -->
				<form onsubmit={(e) => { e.preventDefault(); handleRegister(); }} class="space-y-4">
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="fullName" class="block text-sm font-medium text-gray-700 mb-1">
								Full name (optional)
							</label>
							<Input
								id="fullName"
								type="text"
								bind:value={fullName}
								placeholder="John Doe"
								disabled={loading}
								class="w-full"
							/>
						</div>
						<div>
							<label for="username" class="block text-sm font-medium text-gray-700 mb-1">
								Username *
							</label>
							<Input
								id="username"
								type="text"
								bind:value={username}
								placeholder="johndoe"
								required
								disabled={loading}
								class="w-full"
							/>
						</div>
					</div>

					<div>
						<label for="email" class="block text-sm font-medium text-gray-700 mb-1">
							Email address *
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
							Password *
						</label>
						<div class="relative">
							<Input
								id="password"
								type={showPassword ? 'text' : 'password'}
								bind:value={password}
								placeholder="Create a password"
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
						<p class="text-xs text-gray-500 mt-1">Must be at least 8 characters</p>
					</div>

					<div>
						<label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-1">
							Confirm password *
						</label>
						<div class="relative">
							<Input
								id="confirmPassword"
								type={showConfirmPassword ? 'text' : 'password'}
								bind:value={confirmPassword}
								placeholder="Confirm your password"
								required
								disabled={loading}
								class="w-full pr-10"
							/>
							<button
								type="button"
								class="absolute inset-y-0 right-0 pr-3 flex items-center"
								onclick={() => showConfirmPassword = !showConfirmPassword}
							>
								{#if showConfirmPassword}
									<EyeOff class="h-4 w-4 text-gray-400" />
								{:else}
									<Eye class="h-4 w-4 text-gray-400" />
								{/if}
							</button>
						</div>
					</div>

					<div class="flex items-start">
						<input
							type="checkbox"
							id="terms"
							bind:checked={agreedToTerms}
							class="rounded border-gray-300 text-orange-600 focus:ring-orange-500 mt-1"
							required
						/>
						<label for="terms" class="ml-2 text-sm text-gray-600">
							{m.auth_agree_terms()}
							<a href="/terms" class="text-orange-600 hover:text-orange-500">{m.auth_terms_service()}</a>
							{m.auth_and()}
							<a href="/privacy" class="text-orange-600 hover:text-orange-500">{m.auth_privacy_policy()}</a>
						</label>
					</div>

					<Button type="submit" class="w-full" disabled={loading || !agreedToTerms}>
						{loading ? m.auth_creating_account() : m.auth_create_account()}
					</Button>
				</form>

				<!-- Sign in link -->
				<div class="text-center">
					<p class="text-sm text-gray-600">
						{m.auth_have_account()}
						<a href="/login" class="font-medium text-orange-600 hover:text-orange-500">
							{m.auth_sign_in()}
						</a>
					</p>
				</div>
			</CardContent>
		</Card>
	</div>
</div>