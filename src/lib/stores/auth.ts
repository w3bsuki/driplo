import { supabase } from '$lib/supabase'
import type { User, Session } from '@supabase/supabase-js'
import type { Database } from '$lib/types/database'

type Profile = Database['public']['Tables']['profiles']['Row']

// Auth state using Svelte 5 runes
let user = $state<User | null>(null)
let session = $state<Session | null>(null)
let profile = $state<Profile | null>(null)
let loading = $state(true)

// Initialize auth state
supabase.auth.getSession().then(({ data: { session: initialSession } }) => {
	session = initialSession
	user = initialSession?.user ?? null
	loading = false
	
	if (user) {
		loadProfile(user.id)
	}
})

// Listen for auth changes
supabase.auth.onAuthStateChange(async (event, newSession) => {
	session = newSession
	user = newSession?.user ?? null
	
	if (user) {
		await loadProfile(user.id)
	} else {
		profile = null
	}
	
	loading = false
})

async function loadProfile(userId: string) {
	try {
		const { data, error } = await supabase
			.from('profiles')
			.select('*')
			.eq('id', userId)
			.single()
		
		if (error) throw error
		profile = data
	} catch (error) {
		console.error('Error loading profile:', error)
		profile = null
	}
}

// Auth actions
export const auth = {
	// State getters
	get user() { return user },
	get session() { return session },
	get profile() { return profile },
	get loading() { return loading },
	get isAuthenticated() { return !!user },
	
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
		if (!user) throw new Error('User not authenticated')
		
		const { data, error } = await supabase
			.from('profiles')
			.update(updates)
			.eq('id', user.id)
			.select()
			.single()
		
		if (error) throw error
		profile = data
		return data
	}
}