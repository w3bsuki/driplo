import { createBrowserClient, createServerClient, isBrowser } from '@supabase/ssr'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'
import type { Database } from './types/database'

export const supabase = createBrowserClient<Database>(
	PUBLIC_SUPABASE_URL,
	PUBLIC_SUPABASE_ANON_KEY
)

export function createSupabaseServerClient(fetch: typeof globalThis.fetch) {
	return createServerClient<Database>(
		PUBLIC_SUPABASE_URL,
		PUBLIC_SUPABASE_ANON_KEY,
		{
			cookies: {
				get: (key) => {
					if (!isBrowser()) {
						// Server-side logic here if needed
						return undefined
					}
					return document.cookie
						.split('; ')
						.find(row => row.startsWith(key + '='))
						?.split('=')[1]
				},
				set: (key, value, options) => {
					if (!isBrowser()) {
						// Server-side logic here if needed
						return
					}
					document.cookie = `${key}=${value}; path=/; ${options?.maxAge ? `max-age=${options.maxAge};` : ''}`
				},
				remove: (key, options) => {
					if (!isBrowser()) {
						// Server-side logic here if needed
						return
					}
					document.cookie = `${key}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`
				}
			}
		}
	)
}