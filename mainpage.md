# Main Page Component Analysis

## Page Structure
The main page is built with **Svelte** and renders in this order:

```
+layout.svelte (Global Layout)
├── Header.svelte
├── main (slot content)
│   └── +page.svelte (Home Page)
│       ├── HeroSearch.svelte
│       ├── LandingCategories.svelte
│       ├── QuickFilters.svelte
│       ├── ListingGrid.svelte (Featured)
│       └── ListingGrid.svelte (Most Viewed)
└── MobileNav.svelte
```

## Global Layout Components (`src/routes/+layout.svelte`)

### 1. **Header Component** (`src/lib/components/layout/Header.svelte`)
- **Desktop Features:**
  - Logo with gradient text "Driplo" 
  - Search bar with placeholder "Search for items, brands, or users..."
  - Action buttons (Heart/Favorites, Messages, Profile/Login)
  - Category filter chips (All, Women, Men, Kids, etc.)
- **Mobile Features:**
  - Hamburger menu button
  - Logo
  - Profile/Login button
  - Slide-out navigation panel with menu items and categories
- **Interactive Elements:**
  - Mobile menu overlay with backdrop
  - Category navigation
  - Search functionality

### 2. **Mobile Bottom Navigation** (`src/lib/components/layout/MobileNav.svelte`)
- **5 Navigation Items:**
  - Home (house icon)
  - Browse (search icon)
  - Sell (plus icon, highlighted with gradient)
  - Messages (message circle icon)
  - Filters (filter icon, opens drawer)
- **Design Features:**
  - Fixed bottom position
  - Gradient "Sell" button
  - Active state indicators
  - Smooth transitions

## Main Page Content (`src/routes/+page.svelte`)

### 3. **Hero Search Section** (`src/lib/components/home/HeroSearch.svelte`)
- **Search Bar:**
  - Categories dropdown button with gradient styling
  - Search input with placeholder
  - Search button with magnifying glass icon
  - Gradient background blur effects
- **Trending Elements:**
  - Trending category pills (Dresses, Trainers, Bags, etc.)
  - Trending searches text links (vintage levis, designer bags, etc.)
- **Category Dropdown:**
  - Integrated CategoryDropdown component
  - Smooth animations and transitions

### 4. **Landing Categories** (`src/lib/components/home/LandingCategories.svelte`)
- **Category Grid:**
  - Circular category images with hover effects
  - Category names and item counts
  - Gradient overlays on hover
  - Horizontal scroll on mobile
- **Categories Shown:**
  - All (browse all)
  - Women, Men, Kids, Designer, Shoes, Bags
  - Each with custom unsplash images
- **Interactions:**
  - Hover scale effects
  - Active state styling
  - Category selection navigation

### 5. **Quick Filters** (`src/lib/components/home/QuickFilters.svelte`)
- **Filter Options:**
  - Price ranges (Under £20, £20-50, £50-100, £100+)
  - Sizes (XS, S, M, L, XL)
  - Brands (Nike, Adidas, Zara, H&M, Gucci)
  - Condition (New, Like New, Good, Fair)
- **Layout:**
  - Mobile: Horizontal scrolling filter pills
  - Desktop: Expandable dropdown filters
- **Sort Options:**
  - Most Recent, Price Low/High, Most Popular
  - With emoji icons

### 6. **Featured Listings Grid** (`src/lib/components/listings/ListingGrid.svelte`)
- **First Instance:** Empty title (shows featured items)
- **Second Instance:** "Most viewed" title
- **Grid Layout:**
  - Responsive grid (2 cols mobile → 8 cols desktop)
  - ListingCard components for each item
  - Loading skeleton states
  - Infinite scroll capability
- **Features:**
  - Server-side rendering support
  - Optimized image loading
  - Empty state with call-to-action

### 7. **Individual Listing Cards** (`src/lib/components/listings/ListingCard.svelte`)
- **Product Information:**
  - Product image with aspect ratio 3:4
  - Title, price, size, brand
  - Seller username and avatar
  - Condition indicators
  - Like/favorite functionality
- **Interactive Elements:**
  - Hover effects and animations
  - Click navigation to product details
  - Heart icon for favoriting

## Additional UI Components

### 8. **Shared Components:**
- **CategoryDropdown** (`src/lib/components/shared/CategoryDropdown.svelte`)
- **MobileFiltersDrawer** (`src/lib/components/layout/MobileFiltersDrawer.svelte`)
- **InfiniteScroll** (`src/lib/components/ui/InfiniteScroll.svelte`)

### 9. **Notification System:**
- **Toaster** (from svelte-sonner)
  - Position: top-center
  - Rich colors enabled
  - Global notification system

## Design System

### **Colors:**
- Primary: Orange gradient (#f97316 to #ea580c)
- Background: White with orange-50 accents
- Text: Gray-900 primary, gray-600 secondary
- Borders: Gray-200 default, orange-300 active

### **Typography:**
- Logo: Font-black with gradient text effect
- Headings: Font-semibold
- Body: Font-medium for buttons, normal for text

### **Spacing:**
- Container: px-4 standard padding
- Gaps: 3-4 for grids, 2-3 for smaller elements
- Responsive: md: breakpoint for desktop changes

### **Interactions:**
- Hover: Scale-105, shadow effects
- Active: Scale-95 for buttons
- Transitions: duration-200/300 for smooth animations
- Focus: Orange-500 ring for accessibility

## Data Flow
- Server-side data loading via PageData
- Categories and listings passed as props
- Auth state management via stores
- URL-based filtering and navigation