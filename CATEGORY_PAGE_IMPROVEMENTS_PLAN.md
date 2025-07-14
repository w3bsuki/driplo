# Category Page Improvements Plan

## Current Issues to Address

1. **Remove headline** - Keep only search bar, no need for "Men", "Women" etc. heading
2. **Vertical filters** - Should be horizontal scroll like main page (mobile-first)
3. **Best sellers section** - Need to consider category relevance
4. **Mobile navigation** - Consider bottom sheet for better mobile UX

## Proposed Design

### 1. Top Section
```
┌─────────────────────────────────────┐
│  🔍 Search women's fashion...       │  <- Category-specific search
├─────────────────────────────────────┤
│  Top Sellers in Women               │  <- Avatar row (horizontal scroll)
│  [👤] [👤] [👤] [👤] [👤] →         │
├─────────────────────────────────────┤
│  Categories (Horizontal Scroll)     │
│  [All] [Dresses] [Tops] [Shoes] →  │
├─────────────────────────────────────┤
│  Quick Filters (Horizontal Scroll)  │
│  [Size: M] [Under $50] [New] →     │
└─────────────────────────────────────┘
```

### 2. Best Sellers Section Options

#### Option A: Category-Specific Top Sellers
- Show only sellers who have sold items in this category
- Query: Top sellers by sales count in specific category
- **Pros**: Relevant to what user is looking for
- **Cons**: Might have fewer sellers to show

#### Option B: Top Sellers with Category Items
- Show overall top sellers who HAVE items in this category
- Query: Top sellers who currently have active listings in category
- **Pros**: Shows trusted sellers with relevant items
- **Cons**: May miss specialized sellers

#### Option C: Hybrid Approach (Recommended)
- Primary: Top sellers by category sales
- Fallback: Fill remaining spots with top overall sellers who have items in category
- Shows 5-10 seller avatars with:
  - Avatar image
  - Username
  - Rating stars
  - "230 items" or "Expert in Dresses"

### 3. Mobile-First Filter Design

#### Horizontal Filter Pills (Like Main Page)
```
Categories:  [All] [Dresses] [Tops] [Shoes] [Bags] →
Sizes:       [XS] [S] [M] [L] [XL] →
Price:       [<$20] [$20-50] [$50-100] [$100+] →
Condition:   [New] [Like New] [Good] →
```

#### Bottom Sheet Navigation (Alternative)
```
┌─────────────────────────────────────┐
│  Product Grid                       │
│  ┌────┐ ┌────┐ ┌────┐             │
│  │    │ │    │ │    │             │
│  └────┘ └────┘ └────┘             │
├─────────────────────────────────────┤
│  [🔍] [Filter] [Sort] [Category]   │  <- Fixed bottom bar
└─────────────────────────────────────┘

Tapping "Filter" opens bottom sheet:
┌─────────────────────────────────────┐
│  ═══════════════                    │  <- Drag handle
│  Filters                        [X] │
├─────────────────────────────────────┤
│  Categories                         │
│  ○ All  ● Dresses  ○ Tops         │
├─────────────────────────────────────┤
│  Size                               │
│  [XS] [S] [M] [L] [XL]             │
├─────────────────────────────────────┤
│  Price Range                        │
│  [$] [$$] [$$$] [$$$$]            │
├─────────────────────────────────────┤
│  [Clear All]    [Apply Filters]    │
└─────────────────────────────────────┘
```

## Implementation Approach

### Phase 1: Top Sellers Section
1. Create `TopSellers.svelte` component
2. Implement ShadCN Avatar component
3. Query logic for category-specific sellers
4. Horizontal scroll with momentum

### Phase 2: Mobile-First Filters
Choose between:
- **Option A**: Horizontal scroll filters (simpler, consistent with main page)
- **Option B**: Bottom sheet (more space, better for complex filtering)
- **Option C**: Hybrid - Basic filters horizontal, advanced in sheet

### Phase 3: Search Enhancement
- Remove category heading
- Make search bar sticky
- Add search suggestions based on category

## Database Queries Needed

### Top Sellers Query
```sql
-- Get top sellers in specific category
SELECT 
  p.id,
  p.username,
  p.avatar_url,
  p.seller_rating,
  COUNT(DISTINCT l.id) as items_sold,
  COUNT(DISTINCT active_listings.id) as active_items
FROM profiles p
JOIN listings l ON l.seller_id = p.id
JOIN transactions t ON t.listing_id = l.id
LEFT JOIN listings active_listings ON 
  active_listings.seller_id = p.id 
  AND active_listings.category_id = $1
  AND active_listings.status = 'active'
WHERE 
  l.category_id = $1
  AND t.status = 'completed'
GROUP BY p.id
ORDER BY items_sold DESC
LIMIT 10;
```

## Component Structure

```
src/lib/components/category/
├── TopSellers.svelte          # Horizontal avatar scroll
├── CategoryFilters.svelte     # Horizontal filter pills
├── FilterBottomSheet.svelte   # Alternative filter UI
└── CategorySearch.svelte      # Enhanced search bar
```

## Mobile UX Considerations

### Pros of Horizontal Filters
- Consistent with main page
- Always visible
- Quick access
- No extra taps

### Pros of Bottom Sheet
- More space for filters
- Better for complex filtering
- Cleaner initial view
- Native mobile pattern

### Hybrid Approach (Recommended)
1. **Visible Pills**: Most common filters (Size M, Under $50)
2. **"More Filters"**: Opens bottom sheet for advanced options
3. **Smart Defaults**: Pre-select common choices
4. **Recent Filters**: Remember user preferences

## Visual Design

### Top Sellers Row
```svelte
<div class="flex gap-4 overflow-x-auto pb-2 scrollbar-hide">
  {#each topSellers as seller}
    <a href="/profile/{seller.username}" class="flex-shrink-0">
      <div class="flex flex-col items-center gap-1">
        <Avatar>
          <AvatarImage src={seller.avatar_url} />
          <AvatarFallback>{seller.username[0]}</AvatarFallback>
        </Avatar>
        <span class="text-xs font-medium">{seller.username}</span>
        <div class="flex items-center gap-0.5">
          <Star class="w-3 h-3 fill-yellow-400 text-yellow-400" />
          <span class="text-xs">{seller.rating}</span>
        </div>
      </div>
    </a>
  {/each}
</div>
```

### Filter Pills
```svelte
<div class="flex gap-2 overflow-x-auto pb-2">
  <Button variant="outline" size="sm" class="flex-shrink-0">
    Size: M
  </Button>
  <Button variant="outline" size="sm" class="flex-shrink-0">
    Under $50
  </Button>
  <Button variant="outline" size="sm" class="flex-shrink-0">
    New with tags
  </Button>
  <Button variant="ghost" size="sm" class="flex-shrink-0">
    More filters →
  </Button>
</div>
```

## Decisions Made

1. **Top Sellers**: Show TOP 3 only (no scroll, gamification element)
   - **Category-specific**: Only sellers with ACTIVE items in that category
   - **Ranking**: Based on their performance IN THAT CATEGORY
2. **Filter Approach**: Option C - Hybrid approach
3. **Seller Info**: 
   - Desktop: Avatar + Name + Rating + Sales count
   - Mobile: Avatar + Name + Rating (compact)
4. **Filter Persistence**: Yes, remember common filters
5. **Search Behavior**: Category-confined search

## Seller Display Logic

### Option 1: Active Listings Based (Recommended)
Show sellers who CURRENTLY have items for sale in this category:
- **Query**: Top sellers with active listings in category
- **Ranking**: By their rating from sales in THIS category
- **Benefit**: 100% relevant - shoppers can buy from them now
- **Example**: In Women's, only show sellers selling women's items

### Option 2: Historical Performance
Show sellers based on past sales in category:
- **Query**: Top sellers by historical sales in category
- **Risk**: They might not have items now
- **Not recommended**: Less useful for shoppers

### Option 3: Separate Sections
```
🏆 Top Sellers in Women (Active Now)
[Sellers with women's items currently]

⭐ Best Rated Overall 
[Platform-wide top sellers - shown elsewhere]
```

## Final Design

### Top 3 Sellers Section (Mobile)
```
┌─────────────────────────────────────┐
│  🏆 Top Sellers in Women            │
│ ┌───┐ ┌───┐ ┌───┐                  │
│ │👤│ │👤│ │👤│                  │
│ └───┘ └───┘ └───┘                  │
│ Jane  Mike  Sara                    │
│ ⭐4.9  ⭐4.8  ⭐4.8                   │
└─────────────────────────────────────┘
```

### Desktop View (More Info)
```
┌─────────────────────────────────────┐
│  🏆 Top Sellers in Women            │
│ ┌───┐ ┌───┐ ┌───┐                  │
│ │👤│ │👤│ │👤│                  │
│ └───┘ └───┘ └───┘                  │
│ Jane  Mike  Sara                    │
│ ⭐4.9  ⭐4.8  ⭐4.8                   │
│ 230↗  156↗  98↗   (sales)          │
└─────────────────────────────────────┘
```

### Gamification Benefits
- **Competition**: Sellers compete for top 3 spots
- **Visibility**: Top sellers get premium placement
- **Trust**: Users see most successful sellers
- **Clean UI**: No horizontal scroll needed

### Implementation Priority

1. **Phase 1**: Top 3 Sellers
   - Create compact seller cards
   - Query top 3 by category sales
   - Add hover states and links

2. **Phase 2**: Hybrid Filters
   - Common filters as pills (Size, Price)
   - "More filters" opens bottom sheet
   - Remember user preferences

3. **Phase 3**: Enhanced Search
   - Remove category heading
   - Sticky search bar
   - Category-specific placeholders

## Smart Query for Category Sellers

### Recommended Query Logic
```sql
-- Get top 3 sellers who:
-- 1. Have active items in this category NOW
-- 2. Ranked by their performance in THIS category
SELECT 
  p.id,
  p.username,
  p.avatar_url,
  -- Calculate rating only from THIS category's sales
  AVG(r.rating) FILTER (WHERE l.category_id = $1) as category_rating,
  COUNT(DISTINCT t.id) FILTER (WHERE l.category_id = $1) as category_sales,
  COUNT(DISTINCT active.id) as active_items_count
FROM profiles p
-- Must have active listings in category
JOIN listings active ON 
  active.seller_id = p.id 
  AND active.category_id = $1
  AND active.status = 'active'
-- Get their ratings from category sales
LEFT JOIN listings l ON l.seller_id = p.id
LEFT JOIN transactions t ON t.listing_id = l.id AND t.status = 'completed'
LEFT JOIN user_ratings r ON r.transaction_id = t.id
WHERE active.id IS NOT NULL
GROUP BY p.id
HAVING COUNT(DISTINCT active.id) > 0
ORDER BY 
  category_rating DESC NULLS LAST,
  category_sales DESC,
  active_items_count DESC
LIMIT 3;
```

### Why This Approach?
1. **100% Relevant**: Only shows sellers you can buy from NOW
2. **Category Performance**: Rankings based on their success in THAT category
3. **No Confusion**: Women's page only shows women's clothing sellers
4. **Fresh Data**: If seller stops selling in category, they drop off
5. **Fair Competition**: New sellers can break into top 3 by performing well

## Supabase Implementation & Performance

### Performance Considerations
1. **Complex Query**: The join across profiles, listings, transactions, and ratings could be slow
2. **Solution**: Create a materialized view or computed column for performance

### Option 1: Materialized View (Recommended for Production)
```sql
-- Create a materialized view that updates periodically
CREATE MATERIALIZED VIEW seller_category_stats AS
SELECT 
  p.id as seller_id,
  c.id as category_id,
  p.username,
  p.avatar_url,
  COUNT(DISTINCT active.id) as active_items,
  COUNT(DISTINCT t.id) as total_sales,
  AVG(r.rating) as avg_rating,
  MAX(t.completed_at) as last_sale_date
FROM profiles p
CROSS JOIN categories c
LEFT JOIN listings active ON 
  active.seller_id = p.id 
  AND active.category_id = c.id
  AND active.status = 'active'
LEFT JOIN listings l ON 
  l.seller_id = p.id 
  AND l.category_id = c.id
LEFT JOIN transactions t ON 
  t.listing_id = l.id 
  AND t.status = 'completed'
LEFT JOIN user_ratings r ON r.transaction_id = t.id
WHERE c.parent_id IS NULL -- Only main categories
GROUP BY p.id, c.id, p.username, p.avatar_url;

-- Create index for fast queries
CREATE INDEX idx_seller_category_stats ON seller_category_stats(category_id, avg_rating DESC, total_sales DESC);

-- Refresh every hour (or on-demand)
REFRESH MATERIALIZED VIEW seller_category_stats;
```

### Option 2: Database Function (Simpler)
```sql
CREATE OR REPLACE FUNCTION get_top_category_sellers(category_uuid UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  avatar_url TEXT,
  category_rating NUMERIC,
  category_sales BIGINT,
  active_items BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.username,
    p.avatar_url,
    COALESCE(AVG(r.rating), 0)::NUMERIC as category_rating,
    COUNT(DISTINCT t.id) as category_sales,
    COUNT(DISTINCT active.id) as active_items
  FROM profiles p
  JOIN listings active ON 
    active.seller_id = p.id 
    AND active.category_id = category_uuid
    AND active.status = 'active'
  LEFT JOIN transactions t ON 
    t.seller_id = p.id 
    AND t.status = 'completed'
    AND EXISTS (
      SELECT 1 FROM listings l 
      WHERE l.id = t.listing_id 
      AND l.category_id = category_uuid
    )
  LEFT JOIN user_ratings r ON 
    r.transaction_id = t.id
  GROUP BY p.id, p.username, p.avatar_url
  HAVING COUNT(DISTINCT active.id) > 0
  ORDER BY 
    category_rating DESC,
    category_sales DESC,
    active_items DESC
  LIMIT 3;
END;
$$ LANGUAGE plpgsql;
```

### Supabase Query in SvelteKit
```typescript
// In +page.server.ts
export async function loadCategoryPage(categorySlug: string) {
  // Get category
  const { data: category } = await supabase
    .from('categories')
    .select('*')
    .eq('slug', categorySlug)
    .single();

  // Option 1: Using materialized view (fastest)
  const { data: topSellers } = await supabase
    .from('seller_category_stats')
    .select('*')
    .eq('category_id', category.id)
    .gt('active_items', 0)
    .order('avg_rating', { ascending: false })
    .order('total_sales', { ascending: false })
    .limit(3);

  // Option 2: Using RPC function
  const { data: topSellers } = await supabase
    .rpc('get_top_category_sellers', { category_uuid: category.id });

  // Get products (existing query)
  const { data: products } = await supabase
    .from('listings')
    .select('*, seller:profiles!seller_id(username, avatar_url)')
    .eq('category_id', category.id)
    .eq('status', 'active')
    .order('created_at', { ascending: false });

  return {
    category,
    topSellers,
    products,
    subcategories
  };
}
```

### Production Optimizations
1. **Cache Top Sellers**: Since they don't change often, cache for 5-10 minutes
2. **Background Updates**: Refresh materialized view via cron job
3. **Fallback Logic**: If < 3 sellers, show "Become a top seller!" CTA
4. **Edge Caching**: Use Vercel/Cloudflare edge caching for category pages

### Migration for Production
```sql
-- Add this migration to set up the performance optimization
CREATE MATERIALIZED VIEW IF NOT EXISTS seller_category_stats AS
-- (view definition from above)

-- Create a scheduled job to refresh (using pg_cron or Supabase dashboard)
SELECT cron.schedule(
  'refresh-seller-stats',
  '0 * * * *', -- Every hour
  'REFRESH MATERIALIZED VIEW seller_category_stats;'
);

## Component Specs

### TopThreeSellers.svelte
```svelte
<script>
  import { Avatar, AvatarImage, AvatarFallback } from "$lib/components/ui/avatar";
  
  export let sellers = [];
  export let category;
</script>

<div class="bg-white p-4 border-b">
  <h3 class="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-1">
    <span>🏆</span> Top Sellers in {category.name}
  </h3>
  <div class="grid grid-cols-3 gap-4">
    {#each sellers.slice(0, 3) as seller, index}
      <a href="/profile/{seller.username}" class="text-center group">
        <div class="relative">
          {#if index === 0}
            <div class="absolute -top-1 -right-1 text-xs">👑</div>
          {/if}
          <Avatar class="w-12 h-12 mx-auto mb-1 ring-2 ring-transparent group-hover:ring-purple-200 transition-all">
            <AvatarImage src={seller.avatar_url} alt={seller.username} />
            <AvatarFallback>{seller.username[0]}</AvatarFallback>
          </Avatar>
        </div>
        <p class="text-xs font-medium truncate">{seller.username}</p>
        <div class="flex items-center justify-center gap-0.5 text-xs">
          <span>⭐</span>
          <span>{seller.rating.toFixed(1)}</span>
        </div>
        <!-- Only show on larger screens -->
        <p class="text-xs text-gray-500 hidden sm:block">{seller.sales_count} sales</p>
      </a>
    {/each}
  </div>
</div>
```

### Quick Filters (Hybrid)
```svelte
<!-- Common filters always visible -->
<div class="flex gap-2 overflow-x-auto p-4 bg-gray-50">
  <Button variant={selectedSize ? "default" : "outline"} size="sm">
    Size: {selectedSize || "All"}
  </Button>
  <Button variant={priceRange ? "default" : "outline"} size="sm">
    {priceRange || "Any Price"}
  </Button>
  <Button variant={condition ? "default" : "outline"} size="sm">
    {condition || "Any Condition"}
  </Button>
  <Button variant="ghost" size="sm" onclick={() => showBottomSheet = true}>
    More filters →
  </Button>
</div>

<!-- Bottom sheet for advanced filters -->
<Sheet open={showBottomSheet} onOpenChange={setShowBottomSheet}>
  <SheetContent side="bottom" class="h-[80vh]">
    <SheetHeader>
      <SheetTitle>All Filters</SheetTitle>
    </SheetHeader>
    <!-- Advanced filter options -->
  </SheetContent>
</Sheet>
```

## Next Steps

1. Implement TopThreeSellers component
2. Convert vertical filters to horizontal pills
3. Add bottom sheet for advanced filters
4. Remove category heading, keep search
5. Test mobile experience