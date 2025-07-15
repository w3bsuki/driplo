<script lang="ts">
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { user } from '$lib/stores/auth'
	import { supabase } from '$lib/supabase'
	import { Button } from '$lib/components/ui'
	import { Badge } from '$lib/components/ui/badge'
	import { toast } from 'svelte-sonner'
	import { 
		Camera, Upload, X, Plus, MapPin, Package, 
		DollarSign, Truck, Tag, ChevronLeft, ChevronRight,
		Sparkles, AlertCircle, Check
	} from 'lucide-svelte'
	import { uploadMultipleImages, fileToBase64, validateImageFile } from '$lib/utils/storage'
	import type { Database } from '$lib/types/database'
	import * as m from '$lib/paraglide/messages.js'
	
	type ListingInsert = Database['public']['Tables']['listings']['Insert']
	type Category = Database['public']['Tables']['categories']['Row']
	
	// Props
	interface Props {
		onSuccess?: (listingId: string) => void
	}
	
	let { onSuccess }: Props = $props()
	
	// Form state
	let currentStep = $state(1)
	let isSubmitting = $state(false)
	let categories = $state<Category[]>([])
	let uploadProgress = $state(0)
	
	// Form data
	let formData = $state<{
		// Step 1: Basic Info
		title: string
		description: string
		category_id: string
		subcategory: string
		
		// Step 2: Images
		images: File[]
		imageUrls: string[]
		imagePreviews: string[]
		
		// Step 3: Pricing & Details
		price: number
		condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor'
		size: string
		brand: string
		color: string
		
		// Step 4: Shipping & Location
		shipping_type: 'standard' | 'express' | 'pickup_only'
		shipping_cost: number
		location: string
		tags: string[]
	}>({
		title: '',
		description: '',
		category_id: '',
		subcategory: '',
		images: [],
		imageUrls: [],
		imagePreviews: [],
		price: 0,
		condition: 'good',
		size: '',
		brand: '',
		color: '',
		shipping_type: 'standard',
		shipping_cost: 0,
		location: '',
		tags: []
	})
	
	// Validation
	const stepValidation = $derived({
		1: formData.title.length >= 3 && formData.description.length >= 10,
		2: formData.images.length > 0,
		3: formData.price > 0,
		4: formData.location.length > 0
	})
	
	const canProceed = $derived(stepValidation[currentStep as keyof typeof stepValidation])
	const totalSteps = 4
	const stepProgress = $derived((currentStep / totalSteps) * 100)
	
	// Computed properties
	const suggestedTags = $derived(() => {
		const tags: string[] = []
		if (formData.brand) tags.push(formData.brand.toLowerCase())
		if (formData.color) tags.push(formData.color.toLowerCase())
		if (formData.condition === 'new') tags.push('new')
		if (formData.shipping_type === 'express') tags.push('fast-shipping')
		return tags.filter(tag => !formData.tags.includes(tag))
	})
	
	onMount(async () => {
		await loadCategories()
	})
	
	async function loadCategories() {
		const { data, error } = await supabase
			.from('categories')
			.select('*')
			.is('parent_id', null)  // Only get main categories
			.eq('is_active', true)
			.order('display_order')
		
		if (error) {
			console.error('Error loading categories:', error)
			toast.error(m.listing_error_categories())
			// Add default categories with proper UUIDs
			categories = [
				{ id: '550e8400-e29b-41d4-a716-446655440001', name: 'Women', icon: '👗', slug: 'women', is_active: true },
				{ id: '550e8400-e29b-41d4-a716-446655440002', name: 'Men', icon: '👔', slug: 'men', is_active: true },
				{ id: '550e8400-e29b-41d4-a716-446655440005', name: 'Shoes', icon: '👟', slug: 'shoes', is_active: true },
				{ id: '550e8400-e29b-41d4-a716-446655440004', name: 'Accessories', icon: '👜', slug: 'accessories', is_active: true }
			] as any
		} else {
			categories = data || []
			console.log('Loaded categories:', $state.snapshot(categories))
		}
	}
	
	async function handleImageSelect(event: Event) {
		const input = event.target as HTMLInputElement
		if (!input.files) return
		
		const newFiles = Array.from(input.files)
		const validFiles: File[] = []
		
		for (const file of newFiles) {
			const error = validateImageFile(file)
			if (error) {
				toast.error(error)
			} else if (formData.images.length + validFiles.length < 10) {
				validFiles.push(file)
			}
		}
		
		if (validFiles.length + formData.images.length > 10) {
			toast.error(m.listing_error_image_max())
			return
		}
		
		// Add files and generate previews
		for (const file of validFiles) {
			const preview = await fileToBase64(file)
			formData.images = [...formData.images, file]
			formData.imagePreviews = [...formData.imagePreviews, preview]
		}
	}
	
	function removeImage(index: number) {
		formData.images = formData.images.filter((_, i) => i !== index)
		formData.imagePreviews = formData.imagePreviews.filter((_, i) => i !== index)
	}
	
	function moveImage(from: number, to: number) {
		if (to < 0 || to >= formData.images.length) return
		
		const images = [...formData.images]
		const previews = [...formData.imagePreviews]
		
		const [movedImage] = images.splice(from, 1)
		const [movedPreview] = previews.splice(from, 1)
		
		images.splice(to, 0, movedImage)
		previews.splice(to, 0, movedPreview)
		
		formData.images = images
		formData.imagePreviews = previews
	}
	
	function addTag(tag: string) {
		if (tag && !formData.tags.includes(tag) && formData.tags.length < 10) {
			formData.tags = [...formData.tags, tag.toLowerCase()]
		}
	}
	
	function removeTag(tag: string) {
		formData.tags = formData.tags.filter(t => t !== tag)
	}
	
	async function handleSubmit() {
		if (!$user) {
			toast.error(m.listing_error_login())
			return
		}
		
		isSubmitting = true
		uploadProgress = 0
		
		try {
			// For now, use placeholder images until storage buckets are set up
			let imageUrls: string[] = []
			
			if (formData.images.length > 0) {
				// Try to upload images
				try {
					const uploadResults = await uploadMultipleImages(
						formData.images,
						'listings',
						$user.id,
						(progress) => { uploadProgress = progress }
					)
					
					// Check for upload errors
					const failedUploads = uploadResults.filter(r => r.error)
					if (failedUploads.length === 0) {
						// Success! Get URLs
						imageUrls = uploadResults
							.filter(r => !r.error && r.url)
							.map(r => r.url)
					} else {
						throw new Error('Storage bucket not set up')
					}
				} catch (uploadError) {
					console.error('Image upload failed:', uploadError)
					// Use placeholder images for now
					imageUrls = formData.images.map((_, index) => 
						`https://picsum.photos/400/600?random=${Date.now()}-${index}`
					)
					toast.error('Image upload failed - check storage bucket policies')
				}
			} else {
				// Use a default placeholder
				imageUrls = [`https://picsum.photos/400/600?random=${Date.now()}`]
			}
			
			// Generate slug from title
			const generateSlug = (title: string) => {
				return title
					.toLowerCase()
					.trim()
					.replace(/[^\w\s-]/g, '') // Remove special chars
					.replace(/\s+/g, '-') // Replace spaces with -
					.replace(/-+/g, '-') // Replace multiple - with single -
					.substring(0, 50) // Limit length
					+ '-' + Date.now().toString(36) // Add unique suffix
			}

			// Validate UUID format
			const isValidUUID = (str: string) => {
				const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
				return uuidRegex.test(str)
			}

			// Debug category_id
			console.log('Form category_id:', formData.category_id)
			console.log('Is valid UUID:', isValidUUID(formData.category_id))

			// Create listing with all fields
			const listingData: any = {
				title: formData.title.trim(),
				description: formData.description.trim(),
				price: formData.price,
				condition: formData.condition,
				images: imageUrls,
				location_city: formData.location.trim(),
				seller_id: $user.id,
				status: 'active',
				slug: generateSlug(formData.title),
				category_id: (formData.category_id && isValidUUID(formData.category_id)) ? formData.category_id : null,
				subcategory_id: (formData.subcategory && isValidUUID(formData.subcategory)) ? formData.subcategory : null,
				size: formData.size || null,
				brand: formData.brand || null,
				color: formData.color || null,
				tags: formData.tags || [],
				ships_worldwide: formData.shipping_type === 'worldwide'
			}
			
			console.log('Listing data to insert:', listingData)
			
			const { data, error } = await supabase
				.from('listings')
				.insert(listingData)
				.select()
				.single()
			
			if (error) throw error
			
			toast.success(m.listing_success())
			
			// Track activity - commented out until user_activities table exists
			// await supabase.from('user_activities').insert({
			// 	user_id: $user.id,
			// 	activity_type: 'listed_item',
			// 	activity_data: {
			// 		listing_id: data.id,
			// 		title: data.title,
			// 		price: data.price,
			// 		image: imageUrls[0]
			// 	}
			// })
			
			if (onSuccess) {
				onSuccess(data.id)
			} else {
				// Redirect to success page
				goto(`/sell/success?id=${data.id}`)
			}
			
		} catch (error) {
			console.error('Error creating listing:', error)
			toast.error(error instanceof Error ? error.message : m.listing_error_creation())
		} finally {
			isSubmitting = false
			uploadProgress = 0
		}
	}
	
	function nextStep() {
		const validation = {
			currentStep,
			canProceed,
			title: formData.title,
			titleLength: formData.title.length,
			description: formData.description,
			descriptionLength: formData.description.length,
			stepValidation: $state.snapshot(stepValidation)
		}
		console.log('Next step clicked. Current validation:', validation)
		
		if (canProceed && currentStep < totalSteps) {
			currentStep++
			console.log('Advanced to step:', currentStep)
		} else {
			console.log('Cannot proceed:', { canProceed, currentStep, totalSteps })
		}
	}
	
	function prevStep() {
		if (currentStep > 1) {
			currentStep--
		}
	}
	
	// Get step title
	const stepTitle = $derived(() => {
		switch (currentStep) {
			case 1: return m.listing_step_basic_info()
			case 2: return m.listing_step_add_photos()
			case 3: return m.listing_step_pricing_details()
			case 4: return m.listing_step_shipping_location()
			default: return ''
		}
	})
</script>

<div class="min-h-screen bg-gray-50 pb-20">
	<!-- Header -->
	<div class="sticky top-0 z-30 bg-white border-b shadow-sm">
		<div class="max-w-2xl mx-auto px-4">
			<div class="flex items-center justify-between py-4">
				<button 
					onclick={() => goto('/sell')}
					class="text-gray-600 hover:text-gray-900"
				>
					<ChevronLeft class="w-5 h-5" />
				</button>
				<h1 class="text-lg font-semibold">{m.listing_create_title()}</h1>
				<div class="w-5 h-5" /> <!-- Spacer -->
			</div>
			
			<!-- Progress Bar -->
			<div class="pb-4">
				<div class="flex items-center justify-between mb-2">
					<span class="text-sm text-gray-600">{m.listing_step_of({ step: currentStep, total: totalSteps })}</span>
					<span class="text-sm font-medium">{stepTitle()}</span>
				</div>
				<div class="w-full bg-gray-200 rounded-full h-2">
					<div 
						class="bg-gradient-to-r from-orange-500 to-red-500 h-2 rounded-full transition-all duration-300"
						style="width: {stepProgress}%"
					></div>
				</div>
			</div>
		</div>
	</div>
	
	<!-- Form Content -->
	<div class="max-w-2xl mx-auto px-4 py-6">
		<form onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
			<!-- Step 1: Basic Info -->
			{#if currentStep === 1}
				<div class="space-y-6 animate-in">
					<div>
						<label for="title" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_title_label()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<input
							id="title"
							type="text"
							bind:value={formData.title}
							placeholder={m.listing_title_placeholder()}
							maxlength="80"
							class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
							required
						/>
						<p class="mt-1 text-xs text-gray-500">{m.listing_title_characters({ count: formData.title.length })}</p>
					</div>
					
					<div>
						<label for="description" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_description_label()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<textarea
							id="description"
							bind:value={formData.description}
							placeholder={m.listing_description_placeholder()}
							rows={6}
							maxlength={1000}
							class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent resize-none"
							required
						></textarea>
						<p class="mt-1 text-xs text-gray-500">{m.listing_description_characters({ count: formData.description.length })}</p>
					</div>
					
					<div>
						<label for="category" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_category_label()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<select
							id="category"
							bind:value={formData.category_id}
							class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
							required
						>
							<option value="">{m.listing_category_placeholder()}</option>
							{#each categories as category}
								<option value={category.id}>
									{category.icon} {category.name}
								</option>
							{/each}
						</select>
					</div>
					
					{#if formData.category_id}
						<div>
							<label for="subcategory" class="block text-sm font-medium text-gray-700 mb-2">
								{m.listing_subcategory_label()}
							</label>
							<input
								id="subcategory"
								type="text"
								bind:value={formData.subcategory}
								placeholder={m.listing_subcategory_placeholder()}
								class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
							/>
						</div>
					{/if}
				</div>
			{/if}
			
			<!-- Step 2: Images -->
			{#if currentStep === 2}
				<div class="space-y-6 animate-in">
					<div>
						<h3 class="text-lg font-semibold mb-2">{m.listing_add_photos_title()}</h3>
						<p class="text-sm text-gray-600 mb-4">
							{m.listing_add_photos_description()}
						</p>
						
						<!-- Image Upload Area -->
						{#if formData.images.length === 0}
							<label 
								for="image-upload"
								class="relative block w-full h-64 border-2 border-dashed border-gray-300 rounded-xl hover:border-orange-500 transition-colors cursor-pointer bg-gray-50"
							>
								<input
									id="image-upload"
									type="file"
									accept="image/*"
									multiple
									onchange={handleImageSelect}
									class="sr-only"
								/>
								<div class="flex flex-col items-center justify-center h-full text-gray-400">
									<Upload class="w-12 h-12 mb-3" />
									<p class="text-sm font-medium">{m.listing_upload_instructions()}</p>
									<p class="text-xs mt-1">{m.listing_upload_formats()}</p>
								</div>
							</label>
						{:else}
							<!-- Image Grid -->
							<div class="grid grid-cols-2 sm:grid-cols-3 gap-4 mb-4">
								{#each formData.imagePreviews as preview, index}
									<div class="relative group aspect-square">
										<img 
											src={preview} 
											alt="Preview {index + 1}"
											class="w-full h-full object-cover rounded-xl"
										/>
										{#if index === 0}
											<div class="absolute top-2 left-2 bg-orange-500 text-white text-xs px-2 py-1 rounded-full">
												{m.listing_cover_image()}
											</div>
										{/if}
										<div class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity rounded-xl flex items-center justify-center gap-2">
											{#if index > 0}
												<button
													type="button"
													onclick={() => moveImage(index, index - 1)}
													class="p-2 bg-white rounded-full text-gray-700 hover:bg-gray-100"
												>
													<ChevronLeft class="w-4 h-4" />
												</button>
											{/if}
											<button
												type="button"
												onclick={() => removeImage(index)}
												class="p-2 bg-white rounded-full text-red-600 hover:bg-gray-100"
											>
												<X class="w-4 h-4" />
											</button>
											{#if index < formData.images.length - 1}
												<button
													type="button"
													onclick={() => moveImage(index, index + 1)}
													class="p-2 bg-white rounded-full text-gray-700 hover:bg-gray-100"
												>
													<ChevronRight class="w-4 h-4" />
												</button>
											{/if}
										</div>
									</div>
								{/each}
								
								{#if formData.images.length < 10}
									<label 
										for="image-upload-more"
										class="aspect-square border-2 border-dashed border-gray-300 rounded-xl hover:border-orange-500 transition-colors cursor-pointer bg-gray-50 flex items-center justify-center"
									>
										<input
											id="image-upload-more"
											type="file"
											accept="image/*"
											multiple
											onchange={handleImageSelect}
											class="sr-only"
										/>
										<div class="text-center">
											<Plus class="w-8 h-8 text-gray-400 mx-auto mb-1" />
											<p class="text-xs text-gray-500">{m.listing_add_more()}</p>
										</div>
									</label>
								{/if}
							</div>
							
							<p class="text-sm text-gray-600">
								{m.listing_images_count({ count: formData.images.length })}
							</p>
						{/if}
					</div>
				</div>
			{/if}
			
			<!-- Step 3: Pricing & Details -->
			{#if currentStep === 3}
				<div class="space-y-6 animate-in">
					<div>
						<label for="price" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_price_label()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<div class="relative">
							<span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">$</span>
							<input
								id="price"
								type="number"
								bind:value={formData.price}
								min="0"
								step="0.01"
								placeholder={m.listing_price_placeholder()}
								class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
								required
							/>
						</div>
					</div>
					
					<div>
						<label for="condition" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_condition_label()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<select
							id="condition"
							bind:value={formData.condition}
							class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
							required
						>
							<option value="new">{m.listing_condition_new()}</option>
							<option value="like_new">{m.listing_condition_like_new()}</option>
							<option value="good">{m.listing_condition_good()}</option>
							<option value="fair">{m.listing_condition_fair()}</option>
							<option value="poor">{m.listing_condition_poor()}</option>
						</select>
					</div>
					
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="brand" class="block text-sm font-medium text-gray-700 mb-2">
								{m.listing_brand_label()}
							</label>
							<input
								id="brand"
								type="text"
								bind:value={formData.brand}
								placeholder={m.listing_brand_placeholder()}
								class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
							/>
						</div>
						
						<div>
							<label for="size" class="block text-sm font-medium text-gray-700 mb-2">
								{m.listing_size_label()}
							</label>
							<input
								id="size"
								type="text"
								bind:value={formData.size}
								placeholder={m.listing_size_placeholder()}
								class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
							/>
						</div>
					</div>
					
					<div>
						<label for="color" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_color_label()}
						</label>
						<input
							id="color"
							type="text"
							bind:value={formData.color}
							placeholder={m.listing_color_placeholder()}
							class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
						/>
					</div>
				</div>
			{/if}
			
			<!-- Step 4: Shipping & Location -->
			{#if currentStep === 4}
				<div class="space-y-6 animate-in">
					<div>
						<label for="location" class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_location_label()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<div class="relative">
							<MapPin class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
							<input
								id="location"
								type="text"
								bind:value={formData.location}
								placeholder={m.listing_location_placeholder()}
								class="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
								required
							/>
						</div>
					</div>
					
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_shipping_options()} <span class="text-red-500">{m.listing_required_field()}</span>
						</label>
						<div class="space-y-3">
							<label class="flex items-start gap-3 p-4 border border-gray-200 rounded-xl cursor-pointer hover:border-orange-500 {formData.shipping_type === 'standard' ? 'border-orange-500 bg-orange-50' : ''}">
								<input
									type="radio"
									bind:group={formData.shipping_type}
									value="standard"
									class="mt-1"
								/>
								<div class="flex-1">
									<div class="font-medium">{m.listing_shipping_standard()}</div>
									<div class="text-sm text-gray-600">{m.listing_shipping_standard_time()}</div>
								</div>
							</label>
							
							<label class="flex items-start gap-3 p-4 border border-gray-200 rounded-xl cursor-pointer hover:border-orange-500 {formData.shipping_type === 'express' ? 'border-orange-500 bg-orange-50' : ''}">
								<input
									type="radio"
									bind:group={formData.shipping_type}
									value="express"
									class="mt-1"
								/>
								<div class="flex-1">
									<div class="font-medium">{m.listing_shipping_express()}</div>
									<div class="text-sm text-gray-600">{m.listing_shipping_express_time()}</div>
								</div>
							</label>
							
							<label class="flex items-start gap-3 p-4 border border-gray-200 rounded-xl cursor-pointer hover:border-orange-500 {formData.shipping_type === 'pickup_only' ? 'border-orange-500 bg-orange-50' : ''}">
								<input
									type="radio"
									bind:group={formData.shipping_type}
									value="pickup_only"
									class="mt-1"
								/>
								<div class="flex-1">
									<div class="font-medium">{m.listing_shipping_pickup()}</div>
									<div class="text-sm text-gray-600">{m.listing_shipping_pickup_desc()}</div>
								</div>
							</label>
						</div>
					</div>
					
					{#if formData.shipping_type !== 'pickup_only'}
						<div>
							<label for="shipping_cost" class="block text-sm font-medium text-gray-700 mb-2">
								{m.listing_shipping_cost_label()}
							</label>
							<div class="relative">
								<span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">$</span>
								<input
									id="shipping_cost"
									type="number"
									bind:value={formData.shipping_cost}
									min="0"
									step="0.01"
									placeholder={m.listing_shipping_cost_placeholder()}
									class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
								/>
							</div>
							<p class="mt-1 text-xs text-gray-500">{m.listing_shipping_cost_free()}</p>
						</div>
					{/if}
					
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">
							{m.listing_tags_label()}
						</label>
						<div class="flex flex-wrap gap-2 mb-3">
							{#each formData.tags as tag}
								<Badge class="bg-orange-100 text-orange-700 pl-3 pr-1 py-1">
									#{tag}
									<button
										type="button"
										onclick={() => removeTag(tag)}
										class="ml-1 p-0.5 hover:bg-orange-200 rounded"
									>
										<X class="w-3 h-3" />
									</button>
								</Badge>
							{/each}
						</div>
						
						{#if suggestedTags().length > 0}
							<div class="mb-3">
								<p class="text-xs text-gray-600 mb-2">{m.listing_suggested_tags()}</p>
								<div class="flex flex-wrap gap-2">
									{#each suggestedTags() as tag}
										<button
											type="button"
											onclick={() => addTag(tag)}
											class="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded-full transition-colors"
										>
											+ {tag}
										</button>
									{/each}
								</div>
							</div>
						{/if}
						
						<input
							type="text"
							placeholder={m.listing_tag_placeholder()}
							onkeydown={(e) => {
								if (e.key === 'Enter') {
									e.preventDefault()
									const input = e.target as HTMLInputElement
									addTag(input.value)
									input.value = ''
								}
							}}
							class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent"
						/>
					</div>
				</div>
			{/if}
			
			<!-- Navigation Buttons -->
			<div class="flex gap-3 mt-8">
				{#if currentStep > 1}
					<Button
						type="button"
						variant="outline"
						onclick={prevStep}
						class="flex-1"
					>
						<ChevronLeft class="w-4 h-4 mr-1" />
						{m.listing_btn_previous()}
					</Button>
				{/if}
				
				{#if currentStep < totalSteps}
					<Button
						type="button"
						onclick={nextStep}
						disabled={!canProceed}
						class="flex-1 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
					>
						{m.listing_btn_next()}
						<ChevronRight class="w-4 h-4 ml-1" />
					</Button>
				{:else}
					<Button
						type="submit"
						disabled={!canProceed || isSubmitting}
						class="flex-1 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
					>
						{#if isSubmitting}
							{#if uploadProgress > 0}
								{m.listing_uploading_progress({ progress: uploadProgress.toFixed(0) })}
							{:else}
								{m.listing_creating()}
							{/if}
						{:else}
							<Sparkles class="w-4 h-4 mr-2" />
							{m.listing_btn_publish()}
						{/if}
					</Button>
				{/if}
			</div>
		</form>
	</div>
</div>

<style>
	@keyframes animate-in {
		from {
			opacity: 0;
			transform: translateX(10px);
		}
		to {
			opacity: 1;
			transform: translateX(0);
		}
	}
	
	.animate-in {
		animation: animate-in 0.2s ease-out;
	}
</style>