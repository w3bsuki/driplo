<script lang="ts">
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { user } from '$lib/stores/auth'
	import { supabase } from '$lib/supabase'
	import { Button } from '$lib/components/ui'
	import ImageUpload from '$lib/components/upload/ImageUpload.svelte'
	import { Save, ArrowLeft, User, Image as ImageIcon } from 'lucide-svelte'
	import { toast } from 'svelte-sonner'

	let profile = $state<any>({})
	let loading = $state(true)
	let saving = $state(false)
	let uploadingAvatar = $state(false)
	let uploadingCover = $state(false)

	// Form fields
	let fullName = $state('')
	let username = $state('')
	let bio = $state('')
	let location = $state('')
	let website = $state('')

	onMount(async () => {
		if (!$user) {
			goto('/auth/login')
			return
		}

		await loadProfile()
	})

	async function loadProfile() {
		try {
			const { data, error } = await supabase
				.from('profiles')
				.select('*')
				.eq('id', $user?.id)
				.single()

			if (error) throw error

			profile = data
			fullName = data.full_name || ''
			username = data.username || ''
			bio = data.bio || ''
			location = data.location || ''
			website = data.website || ''
		} catch (error) {
			console.error('Error loading profile:', error)
			toast.error('Failed to load profile')
		} finally {
			loading = false
		}
	}

	async function handleAvatarUpload(event: CustomEvent<{ file: File; preview: string }>) {
		uploadingAvatar = true

		try {
			const formData = new FormData()
			formData.append('file', event.detail.file)
			formData.append('type', 'avatar')

			const response = await fetch('/api/upload/image', {
				method: 'POST',
				body: formData
			})

			if (!response.ok) {
				throw new Error('Upload failed')
			}

			const result = await response.json()
			profile.avatar_url = result.url
			toast.success('Avatar updated successfully')
		} catch (error) {
			console.error('Avatar upload error:', error)
			toast.error('Failed to upload avatar')
		} finally {
			uploadingAvatar = false
		}
	}

	async function handleCoverUpload(event: CustomEvent<{ file: File; preview: string }>) {
		uploadingCover = true

		try {
			const formData = new FormData()
			formData.append('file', event.detail.file)
			formData.append('type', 'cover')

			const response = await fetch('/api/upload/image', {
				method: 'POST',
				body: formData
			})

			if (!response.ok) {
				throw new Error('Upload failed')
			}

			const result = await response.json()
			profile.cover_url = result.url
			toast.success('Cover image updated successfully')
		} catch (error) {
			console.error('Cover upload error:', error)
			toast.error('Failed to upload cover image')
		} finally {
			uploadingCover = false
		}
	}

	async function saveProfile() {
		if (!username.trim()) {
			toast.error('Username is required')
			return
		}

		saving = true

		try {
			const { error } = await supabase
				.from('profiles')
				.update({
					full_name: fullName.trim() || null,
					username: username.trim(),
					bio: bio.trim() || null,
					location: location.trim() || null,
					website: website.trim() || null,
					updated_at: new Date().toISOString()
				})
				.eq('id', $user?.id)

			if (error) throw error

			toast.success('Profile updated successfully')
			goto(`/profile/${username}`)
		} catch (error: any) {
			console.error('Save profile error:', error)
			if (error.code === '23505') {
				toast.error('Username already taken')
			} else {
				toast.error('Failed to save profile')
			}
		} finally {
			saving = false
		}
	}

	function goBack() {
		if (profile.username) {
			goto(`/profile/${profile.username}`)
		} else {
			goto('/')
		}
	}
</script>

<svelte:head>
	<title>Profile Settings - Threadly</title>
</svelte:head>

<div class="min-h-screen bg-background">
	<!-- Header -->
	<div class="border-b bg-background/95 backdrop-blur-sm sticky top-0 z-40">
		<div class="container max-w-4xl mx-auto px-4 py-4">
			<div class="flex items-center gap-4">
				<Button variant="ghost" size="sm" onclick={goBack}>
					<ArrowLeft class="h-4 w-4 mr-2" />
					Back
				</Button>
				<h1 class="text-xl font-bold">Profile Settings</h1>
			</div>
		</div>
	</div>

	{#if loading}
		<div class="container max-w-4xl mx-auto px-4 py-8">
			<div class="animate-pulse space-y-6">
				<div class="h-48 bg-muted rounded-lg"></div>
				<div class="space-y-4">
					<div class="h-4 bg-muted rounded w-1/4"></div>
					<div class="h-10 bg-muted rounded"></div>
					<div class="h-4 bg-muted rounded w-1/4"></div>
					<div class="h-10 bg-muted rounded"></div>
				</div>
			</div>
		</div>
	{:else}
		<div class="container max-w-4xl mx-auto px-4 py-8 space-y-8">
			<!-- Cover Image -->
			<div>
				<div class="flex items-center gap-2 mb-4">
					<ImageIcon class="h-5 w-5" />
					<h2 class="text-lg font-semibold">Cover Image</h2>
				</div>
				<ImageUpload
					currentImage={profile.cover_url}
					placeholder="Upload cover image"
					aspectRatio="cover"
					disabled={uploadingCover}
					onupload={handleCoverUpload}
					class="max-w-2xl"
				/>
			</div>

			<!-- Avatar -->
			<div>
				<div class="flex items-center gap-2 mb-4">
					<User class="h-5 w-5" />
					<h2 class="text-lg font-semibold">Profile Picture</h2>
				</div>
				<ImageUpload
					currentImage={profile.avatar_url}
					placeholder="Upload profile picture"
					aspectRatio="square"
					disabled={uploadingAvatar}
					onupload={handleAvatarUpload}
					class="max-w-xs"
				/>
			</div>

			<!-- Profile Information -->
			<div class="space-y-6">
				<h2 class="text-lg font-semibold">Profile Information</h2>
				
				<div class="grid gap-6">
					<!-- Full Name -->
					<div>
						<label for="fullName" class="block text-sm font-medium mb-2">
							Full Name
						</label>
						<input
							id="fullName"
							type="text"
							bind:value={fullName}
							placeholder="Enter your full name"
							class="w-full px-4 py-2 border border-input rounded-lg bg-background"
						/>
					</div>

					<!-- Username -->
					<div>
						<label for="username" class="block text-sm font-medium mb-2">
							Username <span class="text-destructive">*</span>
						</label>
						<input
							id="username"
							type="text"
							bind:value={username}
							placeholder="Enter your username"
							class="w-full px-4 py-2 border border-input rounded-lg bg-background"
							required
						/>
					</div>

					<!-- Bio -->
					<div>
						<label for="bio" class="block text-sm font-medium mb-2">
							Bio
						</label>
						<textarea
							id="bio"
							bind:value={bio}
							placeholder="Tell us about yourself..."
							rows="4"
							class="w-full px-4 py-2 border border-input rounded-lg bg-background resize-none"
						></textarea>
					</div>

					<!-- Location -->
					<div>
						<label for="location" class="block text-sm font-medium mb-2">
							Location
						</label>
						<input
							id="location"
							type="text"
							bind:value={location}
							placeholder="Where are you based?"
							class="w-full px-4 py-2 border border-input rounded-lg bg-background"
						/>
					</div>

					<!-- Website -->
					<div>
						<label for="website" class="block text-sm font-medium mb-2">
							Website
						</label>
						<input
							id="website"
							type="url"
							bind:value={website}
							placeholder="https://your-website.com"
							class="w-full px-4 py-2 border border-input rounded-lg bg-background"
						/>
					</div>
				</div>
			</div>

			<!-- Save Button -->
			<div class="flex justify-end pt-6 border-t">
				<Button 
					onclick={saveProfile} 
					disabled={saving || !username.trim()}
					class="min-w-[120px]"
				>
					{#if saving}
						<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
					{:else}
						<Save class="h-4 w-4 mr-2" />
					{/if}
					Save Changes
				</Button>
			</div>
		</div>
	{/if}
</div>