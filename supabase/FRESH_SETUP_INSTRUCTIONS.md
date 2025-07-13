# Fresh Database Setup Instructions

## Why Fresh Setup?
Your current database has accumulated technical debt:
- Conflicting migrations (two 04_ files)
- Broken user trigger
- Type mismatches (listing_likes vs favorites)
- Manual workarounds in auth.ts

## Steps to Clean Setup

### 1. Backup Current Data (if needed)
```sql
-- Export any important data first
```

### 2. Create New Supabase Project OR Reset Current One

#### Option A: New Project (Recommended)
1. Create new Supabase project
2. Copy the URL and anon key
3. Update your .env file

#### Option B: Reset Current Project
1. Go to Settings > General
2. Scroll to "Danger Zone"  
3. Click "Reset Database" (⚠️ This deletes ALL data)

### 3. Run Fresh Setup SQL
1. Go to SQL Editor in Supabase
2. Copy entire contents of `FRESH_DATABASE_SETUP.sql`
3. Run it
4. Should complete without errors

### 4. Configure Authentication
1. Go to Authentication > Providers
2. Enable Email provider
3. Configure redirect URLs:
   - Site URL: `http://localhost:5190`
   - Redirect URLs: `http://localhost:5190/auth/callback`

### 5. Generate Fresh Types
```bash
npx supabase gen types typescript --project-id YOUR_PROJECT_ID > src/lib/types/database.ts
```

### 6. Update Code

#### Remove these files:
- `src/lib/utils/setup-storage.ts` (security risk)
- `src/lib/types/user.ts` (outdated types)
- `src/lib/types/social.ts` (duplicate types)

#### Update auth.ts:
Remove lines 49-78 and 103-121 (manual profile creation)

#### Fix imports:
Replace all imports of `UserProfile` and `EnhancedUserProfile` with:
```typescript
import type { Database } from '$lib/types/database'
type Profile = Database['public']['Tables']['profiles']['Row']
```

## Verification Checklist
- [ ] User signup creates profile automatically
- [ ] All profile fields are initialized with defaults
- [ ] Storage buckets exist (avatars, covers, listings)
- [ ] No type errors in VS Code
- [ ] Auth flows work correctly

## Benefits
- ✅ Single source of truth
- ✅ No manual workarounds
- ✅ Type-safe database access
- ✅ Proper RLS policies
- ✅ Clean migration history