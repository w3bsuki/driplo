import { paraglide } from "@inlang/paraglide-js-adapter-sveltekit/vite"
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [
		paraglide({
			project: "./project.inlang",
			outdir: "./src/lib/paraglide",
		}),
		sveltekit()
	],
	server: {
		port: 5190,
		strictPort: true
	}
});
