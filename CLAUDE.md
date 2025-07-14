# Claude Development Rules

## 1. PLAN - Think Before Acting
Always create a clear plan before implementation. Use TodoWrite to track tasks and break complex problems into smaller steps.

## 2. ANALYZE - Understand the System
Read existing code and migrations before making changes. Check for patterns, dependencies, and potential impacts.

## 3. EXECUTE - Implement Cleanly
- **No duplicates**: Check if functionality already exists
- **No bloat**: Write only what's necessary
- **Keep it simple**: Avoid overengineering solutions
- **No tech debt**: Fix issues properly, not with quick hacks

## 4. VERIFY - Test Your Changes
Always verify migrations and code changes work correctly. Check for side effects and data consistency.

## 5. ITERATE - Continuous Improvement
Review implementations, identify issues early, and refactor when needed. Each iteration should improve the codebase.

## Best Practices
- **Read the docs**: Check framework/library documentation before implementing
- **Follow conventions**: Match existing code style and patterns
- **Think data first**: Ensure database schema supports the features
- **Server-side when possible**: Prefer SSR over client-side data fetching
- **Handle errors gracefully**: Always consider failure scenarios

## Paraglide i18n Cheat Sheet

### 1. Keep the CLI in muscle memory
```bash
# after adding new keys
npx paraglide-js compile --watch   # hot-reload while coding
```

### 2. SSR-safe locale getter
```typescript
// src/lib/i18n.ts
import { languageTag } from '../paraglide/runtime.js'
import { browser } from '$app/environment'

export const getLocale = () =>
  browser ? languageTag() : undefined   // let adapter pick from URL/cookie
```

### 3. Plurals & variables
```json5
// messages/en.json
"items_left": "{count, plural, =0 {Sold out} one {1 item left} other {# items left}}"
```

```svelte
<script>
  import * as m from '$paraglide/messages.js'
  export let count
</script>

{m.items_left({ count })}
```

### 4. One-liner for RTL layouts
```svelte
<svelte:head>
  <html lang={$locale} dir={$locale === 'ar' ? 'rtl' : 'ltr'} />
</svelte:head>
```

### 5. Admin locale override
```typescript
// src/routes/admin/+layout.ts
import { overwriteSetLocale } from '$paraglide/runtime.js'

overwriteSetLocale('en')   // force admin interface to English
```