<script>
	import { page } from '$app/stores'
	import { goto } from '$app/navigation'
	import { i18n } from '$lib/i18n.js'
	import { languageTag } from '$lib/paraglide/runtime.js'
	
	$: currentLanguage = languageTag()
	
	function switchToLanguage(newLang) {
		if (newLang === currentLanguage) return;
		
		// Get the canonical path (without language prefix)
		const canonicalPath = i18n.route($page.url.pathname);
		
		// Navigate to the new language
		if (newLang === 'en') {
			// For English (source language), use the canonical path
			goto(canonicalPath, { replaceState: true });
		} else {
			// For other languages, prefix with language code
			goto(`/${newLang}${canonicalPath}`, { replaceState: true });
		}
	}
</script>

<select on:change={(e) => switchToLanguage(e.target.value)} class="rounded-md border border-input bg-background px-3 py-1.5 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2">
	<option value="en" selected={currentLanguage === 'en'}>English</option>
	<option value="bg" selected={currentLanguage === 'bg'}>Български</option>
</select>