import { writable } from 'svelte/store'
import { goto, invalidateAll } from '$app/navigation'
import { page } from '$app/stores'
import { get } from 'svelte/store'
import type { User, Session } from '@supabase/supabase-js'
import type { Database } from '$lib/types/database'

type Profile = Database['public']['Tables']['profiles']['Row']

// Auth state using Svelte stores - synced with SvelteKit layout data
export const user = writable<User | null>(null)
export const session = writable<Session | null>(null)  
export const profile = writable<Profile | null>(null)
export const loading = writable(false)

// Initialize auth state from SvelteKit layout data
export function initializeAuth(initialUser: User | null, initialSession: Session | null) {
	user.set(initialUser)
	session.set(initialSession)
	
	if (initialUser) {
		loadProfile(initialUser.id)
	} else {
		profile.set(null)
	}
}

async function loadProfile(userId: string) {
	try {
		// Get supabase client from layout data
		const currentPage = get(page)
		const supabase = currentPage.data.supabase
		
		if (!supabase) {
			console.error('Supabase client not available')
			return
		}

		const { data, error } = await supabase
			.from('profiles')
			.select('*')
			.eq('id', userId)
			.single()
		
		if (error) throw error
		profile.set(data)
	} catch (error) {
		console.error('Error loading profile:', error)
		profile.set(null)
	}
}

// Auth actions
export const auth = {
	// Store references
	user,
	session,
	profile,
	loading,
	
	// Auth methods
	async signUp(email: string, password: string, username: string, fullName?: string) {
		loading.set(true)
		try {
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!supabase) throw new Error('Supabase client not available')

			const { data, error } = await supabase.auth.signUp({
				email,
				password,
				options: {
					data: {
						username,
						full_name: fullName
					}
				}
			})
			
			if (error) throw error
			
			// Refresh auth state
			await invalidateAll()
			return data
		} finally {
			loading.set(false)
		}
	},
	
	async signIn(email: string, password: string) {
		loading.set(true)
		try {
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!supabase) throw new Error('Supabase client not available')

			const { data, error } = await supabase.auth.signInWithPassword({
				email,
				password
			})
			
			if (error) throw error
			
			// Refresh auth state
			await invalidateAll()
			return data
		} finally {
			loading.set(false)
		}
	},
	
	async signInWithProvider(provider: 'google' | 'github' | 'apple') {
		loading.set(true)
		try {
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!supabase) throw new Error('Supabase client not available')

			const { data, error } = await supabase.auth.signInWithOAuth({
				provider,
				options: {
					redirectTo: `${window.location.origin}/callback`
				}
			})
			
			if (error) throw error
			return data
		} finally {
			loading.set(false)
		}
	},
	
	async signOut() {
		loading.set(true)
		try {
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!supabase) throw new Error('Supabase client not available')

			const { error } = await supabase.auth.signOut()
			if (error) throw error
			
			// Clear local state
			user.set(null)
			session.set(null)
			profile.set(null)
			
			// Refresh auth state and redirect
			await invalidateAll()
			goto('/')
		} finally {
			loading.set(false)
		}
	},
	
	async resetPassword(email: string) {
		loading.set(true)
		try {
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!supabase) throw new Error('Supabase client not available')

			const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
				redirectTo: `${window.location.origin}/reset-password`
			})
			
			if (error) throw error
			return data
		} finally {
			loading.set(false)
		}
	},
	
	async updatePassword(password: string) {
		loading.set(true)
		try {
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!supabase) throw new Error('Supabase client not available')

			const { data, error } = await supabase.auth.updateUser({
				password
			})
			
			if (error) throw error
			
			// Refresh auth state
			await invalidateAll()
			return data
		} finally {
			loading.set(false)
		}
	},
	
	async updateProfile(updates: Partial<Profile>) {
		loading.set(true)
		try {
			const currentUser = get(user)
			const currentPage = get(page)
			const supabase = currentPage.data.supabase
			
			if (!currentUser) throw new Error('User not authenticated')
			if (!supabase) throw new Error('Supabase client not available')

			const { data, error } = await supabase
				.from('profiles')
				.update(updates)
				.eq('id', currentUser.id)
				.select()
				.single()
			
			if (error) throw error
			profile.set(data)
			return data
		} finally {
			loading.set(false)
		}
	}
}