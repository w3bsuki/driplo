export interface User {
	id: string;
	username: string;
	email: string;
	profile: UserProfile;
	preferences: UserPreferences;
	stats: UserStats;
	createdAt: Date;
	updatedAt: Date;
}

export interface UserProfile {
	displayName: string;
	avatar?: string;
	bio?: string;
	location?: {
		city?: string;
		country?: string;
	};
	verified: boolean;
	sellerRating?: number;
	buyerRating?: number;
}

export interface UserPreferences {
	sizes: {
		clothing?: string[];
		shoes?: string[];
	};
	brands: string[];
	styles: string[];
	notifications: NotificationSettings;
}

export interface NotificationSettings {
	email: {
		newMessage: boolean;
		newOffer: boolean;
		soldItem: boolean;
		marketing: boolean;
	};
	push: {
		newMessage: boolean;
		newOffer: boolean;
		soldItem: boolean;
	};
}

export interface UserStats {
	itemsSold: number;
	itemsBought: number;
	followers: number;
	following: number;
	totalEarnings?: number;
	totalSpent?: number;
}