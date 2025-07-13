<script lang="ts">
	import { createEventDispatcher } from 'svelte'
	import { Upload, X, Camera, Loader2 } from 'lucide-svelte'
	import { Button } from '$lib/components/ui'
	import { cn } from '$lib/utils'

	interface Props {
		currentImage?: string
		placeholder?: string
		aspectRatio?: 'square' | 'cover' | 'free'
		maxSizeBytes?: number
		allowedTypes?: string[]
		class?: string
		disabled?: boolean
	}

	let {
		currentImage = '',
		placeholder = 'Upload image',
		aspectRatio = 'square',
		maxSizeBytes = 5 * 1024 * 1024, // 5MB default
		allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
		class: className = '',
		disabled = false
	}: Props = $props()

	let fileInput: HTMLInputElement
	let previewUrl = $state('')
	let dragOver = $state(false)
	let uploading = $state(false)
	let error = $state('')

	const dispatch = createEventDispatcher<{
		upload: { file: File; preview: string }
		remove: void
		error: string
	}>()

	// Initialize preview with current image
	$effect(() => {
		previewUrl = currentImage
	})

	function handleFileSelect(event: Event) {
		const target = event.target as HTMLInputElement
		const file = target.files?.[0]
		if (file) {
			processFile(file)
		}
	}

	function handleDrop(event: DragEvent) {
		event.preventDefault()
		dragOver = false
		
		const file = event.dataTransfer?.files[0]
		if (file) {
			processFile(file)
		}
	}

	function processFile(file: File) {
		error = ''

		// Validate file type
		if (!allowedTypes.includes(file.type)) {
			error = `Only ${allowedTypes.map(t => t.split('/')[1]).join(', ')} files are allowed`
			dispatch('error', error)
			return
		}

		// Validate file size
		if (file.size > maxSizeBytes) {
			error = `File size must be less than ${Math.round(maxSizeBytes / 1024 / 1024)}MB`
			dispatch('error', error)
			return
		}

		// Create preview
		const reader = new FileReader()
		reader.onload = (e) => {
			previewUrl = e.target?.result as string
			dispatch('upload', { file, preview: previewUrl })
		}
		reader.readAsDataURL(file)
	}

	function removeImage() {
		previewUrl = ''
		currentImage = ''
		if (fileInput) {
			fileInput.value = ''
		}
		dispatch('remove')
	}

	function triggerFileInput() {
		if (!disabled) {
			fileInput?.click()
		}
	}

	function handleDragOver(event: DragEvent) {
		event.preventDefault()
		dragOver = true
	}

	function handleDragLeave(event: DragEvent) {
		event.preventDefault()
		dragOver = false
	}

	// Get aspect ratio classes
	const aspectClasses = $derived(() => {
		switch (aspectRatio) {
			case 'square':
				return 'aspect-square'
			case 'cover':
				return 'aspect-[3/1]'
			case 'free':
			default:
				return 'min-h-[200px]'
		}
	})
</script>

<div class={cn("relative", className)}>
	<input
		bind:this={fileInput}
		type="file"
		accept={allowedTypes.join(',')}
		onchange={handleFileSelect}
		class="hidden"
		{disabled}
	/>

	<div
		class={cn(
			"relative border-2 border-dashed rounded-lg transition-all cursor-pointer",
			aspectClasses,
			dragOver ? "border-primary bg-primary/5" : "border-muted-foreground/25",
			disabled && "opacity-50 cursor-not-allowed",
			previewUrl ? "border-solid border-border" : ""
		)}
		onclick={triggerFileInput}
		ondragover={handleDragOver}
		ondragleave={handleDragLeave}
		ondrop={handleDrop}
	>
		{#if previewUrl}
			<!-- Image Preview -->
			<div class="relative w-full h-full">
				<img
					src={previewUrl}
					alt="Preview"
					class="w-full h-full object-cover rounded-lg"
				/>
				
				<!-- Remove Button -->
				{#if !disabled}
					<button
						onclick={(e) => {
							e.stopPropagation()
							removeImage()
						}}
						class="absolute top-2 right-2 p-1 bg-black/50 text-white rounded-full hover:bg-black/70 transition-colors"
					>
						<X class="h-4 w-4" />
					</button>
				{/if}

				<!-- Change Image Overlay -->
				{#if !disabled}
					<div class="absolute inset-0 bg-black/0 hover:bg-black/10 rounded-lg transition-colors flex items-center justify-center opacity-0 hover:opacity-100">
						<div class="flex items-center gap-2 text-white">
							<Camera class="h-5 w-5" />
							<span class="text-sm font-medium">Change Image</span>
						</div>
					</div>
				{/if}
			</div>
		{:else}
			<!-- Upload Placeholder -->
			<div class="flex flex-col items-center justify-center h-full p-6 text-center">
				{#if uploading}
					<Loader2 class="h-8 w-8 animate-spin text-muted-foreground mb-2" />
					<p class="text-sm text-muted-foreground">Uploading...</p>
				{:else}
					<Upload class="h-8 w-8 text-muted-foreground mb-2" />
					<p class="text-sm font-medium text-foreground mb-1">{placeholder}</p>
					<p class="text-xs text-muted-foreground">
						Drag & drop or click to select
					</p>
					<p class="text-xs text-muted-foreground mt-1">
						{allowedTypes.map(t => t.split('/')[1].toUpperCase()).join(', ')} • Max {Math.round(maxSizeBytes / 1024 / 1024)}MB
					</p>
				{/if}
			</div>
		{/if}
	</div>

	{#if error}
		<p class="text-sm text-destructive mt-2">{error}</p>
	{/if}
</div>