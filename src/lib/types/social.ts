// Social and gamification types for Threadly C2C platform

export type RatingType = 'seller' | 'buyer'

export type AchievementType = 
  | 'first_sale'
  | 'power_seller'
  | 'top_rated'
  | 'verified_seller'
  | 'social_butterfly'
  | 'quick_shipper'
  | 'loyal_customer'
  | 'trendsetter'

export interface UserRating {
  id: string
  rated_user_id: string
  rater_user_id: string
  listing_id?: string
  rating: number // 1-5
  review_text?: string
  rating_type: RatingType
  helpful_count: number
  created_at: string
  updated_at: string
  
  // Relations
  rater?: UserProfile
  listing?: Listing
}

export interface UserAchievement {
  id: string
  user_id: string
  achievement_type: AchievementType
  level: number
  progress: number
  max_progress: number
  earned_at: string
  is_visible: boolean
}

export interface Transaction {
  id: string
  buyer_id: string
  seller_id: string
  listing_id: string
  amount: number
  status: string
  completed_at?: string
  created_at: string
  
  // Relations
  buyer?: UserProfile
  seller?: UserProfile
  listing?: Listing
}

export interface ProfileView {
  id: string
  profile_id: string
  viewer_id?: string
  ip_address?: string
  created_at: string
}

export interface UserActivity {
  id: string
  user_id: string
  activity_type: string
  activity_data: Record<string, any>
  is_public: boolean
  created_at: string
  
  // Relations
  user?: UserProfile
}

// Enhanced profile interface with social features
export interface EnhancedUserProfile {
  id: string
  username: string
  full_name?: string
  avatar_url?: string
  cover_image_url?: string
  bio?: string
  location?: string
  website?: string
  
  // Social stats
  followers_count: number
  following_count: number
  listings_count: number
  profile_views: number
  
  // Seller stats
  seller_rating: number
  seller_rating_count: number
  total_sales: number
  total_earnings: number
  seller_level: number
  
  // Buyer stats
  buyer_rating: number
  buyer_rating_count: number
  total_purchases: number
  
  // Social features
  verification_badges: string[]
  social_links: Record<string, string>
  response_time_hours: number
  completion_percentage: number
  
  // Timestamps
  member_since: string
  last_active: string
  created_at: string
  updated_at: string
  is_verified: boolean
  
  // Relations
  achievements?: UserAchievement[]
  recent_ratings?: UserRating[]
  recent_activities?: UserActivity[]
}

// Achievement definitions with metadata
export interface AchievementDefinition {
  type: AchievementType
  name: string
  description: string
  icon: string
  color: string
  requirement: string
  levels: {
    level: number
    name: string
    requirement: string
    reward?: string
  }[]
}

// Social verification badges
export interface VerificationBadge {
  type: 'email' | 'phone' | 'id' | 'business' | 'address' | 'social'
  verified_at: string
  expires_at?: string
}

// Rating summary for display
export interface RatingSummary {
  average_rating: number
  total_count: number
  distribution: {
    5: number
    4: number
    3: number
    2: number
    1: number
  }
  recent_reviews: UserRating[]
}

// Social activity types
export type ActivityType = 
  | 'listed_item'
  | 'made_sale'
  | 'got_review'
  | 'achievement_unlocked'
  | 'new_follower'
  | 'verified_account'
  | 'level_up'

// Seller performance metrics
export interface SellerMetrics {
  total_sales: number
  total_revenue: number
  average_rating: number
  response_time: number
  completion_rate: number
  repeat_customer_rate: number
  items_sold_last_30_days: number
  revenue_last_30_days: number
  trending_score: number
}

// Top seller leaderboard entry
export interface TopSeller {
  profile: EnhancedUserProfile
  metrics: SellerMetrics
  rank: number
  badge_color: 'gold' | 'silver' | 'bronze' | 'rising'
}

// Social feed item
export interface FeedItem {
  id: string
  user: UserProfile
  activity_type: ActivityType
  content: string
  data: Record<string, any>
  created_at: string
  engagement: {
    likes: number
    comments: number
    views: number
  }
}