import { writable } from 'svelte/store'
import { supabase } from '$lib/supabase'
import type { User, Session } from '@supabase/supabase-js'
import type { Database } from '$lib/types/database'

type Profile = Database['public']['Tables']['profiles']['Row']

// Auth state using Svelte stores
export const user = writable<User | null>(null)
export const session = writable<Session | null>(null)
export const profile = writable<Profile | null>(null)
export const loading = writable(true)

// Initialize auth state
supabase.auth.getSession().then(({ data: { session: initialSession } }) => {
	session.set(initialSession)
	user.set(initialSession?.user ?? null)
	loading.set(false)
	
	if (initialSession?.user) {
		loadProfile(initialSession.user.id)
	}
})

// Listen for auth changes
supabase.auth.onAuthStateChange(async (event, newSession) => {
	session.set(newSession)
	user.set(newSession?.user ?? null)
	
	if (newSession?.user) {
		await loadProfile(newSession.user.id)
	} else {
		profile.set(null)
	}
	
	loading.set(false)
})

async function loadProfile(userId: string) {
	try {
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
		return data
	},
	
	async signIn(email: string, password: string) {
		const { data, error } = await supabase.auth.signInWithPassword({
			email,
			password
		})
		
		if (error) throw error
		return data
	},
	
	async signInWithProvider(provider: 'google' | 'github' | 'apple') {
		const { data, error } = await supabase.auth.signInWithOAuth({
			provider,
			options: {
				redirectTo: `${window.location.origin}/auth/callback`
			}
		})
		
		if (error) throw error
		return data
	},
	
	async signOut() {
		const { error } = await supabase.auth.signOut()
		if (error) throw error
	},
	
	async resetPassword(email: string) {
		const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
			redirectTo: `${window.location.origin}/auth/reset-password`
		})
		
		if (error) throw error
		return data
	},
	
	async updatePassword(password: string) {
		const { data, error } = await supabase.auth.updateUser({
			password
		})
		
		if (error) throw error
		return data
	},
	
	async updateProfile(updates: Partial<Profile>) {
		const currentUser = await new Promise<User | null>(resolve => {
			const unsubscribe = user.subscribe(value => {
				unsubscribe()
				resolve(value)
			})
		})
		
		if (!currentUser) throw new Error('User not authenticated')
		
		const { data, error } = await supabase
			.from('profiles')
			.update(updates)
			.eq('id', currentUser.id)
			.select()
			.single()
		
		if (error) throw error
		profile.set(data)
		return data
	}
}