import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		port: 5190,
		strictPort: false,
		hmr: {
			overlay: true
		},
		watch: {
			// Ignore watch on problematic paths
			ignored: ['**/node_modules/**', '**/.git/**', '**/dist/**', '**/.svelte-kit/**']
		}
	},
	optimizeDeps: {
		// Force include svelte-sonner to fix PostCSS issue
		include: ['bits-ui', 'lucide-svelte', 'svelte-sonner']
	},
	ssr: {
		noExternal: ['svelte-sonner']
	}
});
