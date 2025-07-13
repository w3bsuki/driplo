// This is a one-time setup script to create storage buckets
// Run this in the browser console or as a server-side script

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY! // Service key with admin access

export async function setupStorageBuckets() {
	const supabase = createClient(supabaseUrl, supabaseServiceKey)
	
	// Create buckets
	const buckets = ['avatars', 'covers', 'listings']
	
	for (const bucketName of buckets) {
		const { data, error } = await supabase.storage.createBucket(bucketName, {
			public: true,
			fileSizeLimit: 10485760, // 10MB
			allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
		})
		
		if (error) {
			console.error(`Error creating bucket ${bucketName}:`, error)
		} else {
			console.log(`Bucket ${bucketName} created successfully`)
		}
	}
	
	// Set up storage policies
	// Note: These need to be done via Supabase Dashboard as the JS client doesn't support policy creation
	console.log(`
Storage buckets created! 

Now go to your Supabase Dashboard > Storage and set these policies:

1. For 'avatars' bucket:
   - Allow authenticated users to upload (INSERT)
   - Allow public to view (SELECT)

2. For 'covers' bucket:
   - Allow authenticated users to upload (INSERT)
   - Allow public to view (SELECT)

3. For 'listings' bucket:
   - Allow authenticated users to upload (INSERT)
   - Allow public to view (SELECT)
	`)
}