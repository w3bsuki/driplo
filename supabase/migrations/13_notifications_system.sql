-- =====================================================
-- Notifications System
-- =====================================================

-- Notification types
CREATE TYPE notification_type AS ENUM (
    'order_placed',
    'order_paid',
    'order_shipped',
    'order_delivered',
    'order_cancelled',
    'new_message',
    'new_rating',
    'new_follower',
    'listing_favorited',
    'listing_sold',
    'price_drop',
    'return_requested',
    'payment_received',
    'achievement_earned',
    'promotion_alert'
);

-- Notification channels
CREATE TYPE notification_channel AS ENUM ('in_app', 'email', 'push');

-- Notifications table
CREATE TABLE notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    
    -- Notification content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url TEXT,
    icon_url TEXT,
    image_url TEXT,
    
    -- Related entities
    related_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    related_order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    related_listing_id UUID REFERENCES listings(id) ON DELETE CASCADE,
    related_message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    is_archived BOOLEAN DEFAULT FALSE,
    archived_at TIMESTAMPTZ,
    
    -- Delivery status
    channels_sent notification_channel[] DEFAULT '{}',
    email_sent_at TIMESTAMPTZ,
    push_sent_at TIMESTAMPTZ,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days')
);

-- User notification preferences
CREATE TABLE notification_preferences (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Global settings
    all_notifications BOOLEAN DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '08:00',
    
    -- Email preferences by type
    email_orders BOOLEAN DEFAULT TRUE,
    email_messages BOOLEAN DEFAULT TRUE,
    email_social BOOLEAN DEFAULT TRUE,
    email_marketing BOOLEAN DEFAULT FALSE,
    email_digest BOOLEAN DEFAULT TRUE,
    email_digest_frequency VARCHAR(20) DEFAULT 'weekly', -- 'daily', 'weekly', 'monthly'
    
    -- Push preferences by type
    push_orders BOOLEAN DEFAULT TRUE,
    push_messages BOOLEAN DEFAULT TRUE,
    push_social BOOLEAN DEFAULT TRUE,
    push_marketing BOOLEAN DEFAULT FALSE,
    
    -- In-app preferences
    in_app_all BOOLEAN DEFAULT TRUE,
    in_app_sound BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification templates for consistent messaging
CREATE TABLE notification_templates (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type notification_type NOT NULL UNIQUE,
    title_template TEXT NOT NULL,
    message_template TEXT NOT NULL,
    email_subject_template TEXT,
    email_body_template TEXT,
    push_body_template TEXT,
    variables JSONB DEFAULT '[]', -- List of available variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

-- Notification policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Preference policies
CREATE POLICY "Users can view their preferences" ON notification_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their preferences" ON notification_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Template policies (read-only for users)
CREATE POLICY "Templates are viewable by everyone" ON notification_templates
    FOR SELECT USING (is_active = true);

-- Indexes
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_expires ON notifications(expires_at);
CREATE INDEX idx_notifications_related_order ON notifications(related_order_id) WHERE related_order_id IS NOT NULL;
CREATE INDEX idx_notifications_related_listing ON notifications(related_listing_id) WHERE related_listing_id IS NOT NULL;

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type notification_type,
    p_title TEXT,
    p_message TEXT,
    p_action_url TEXT DEFAULT NULL,
    p_related_user_id UUID DEFAULT NULL,
    p_related_order_id UUID DEFAULT NULL,
    p_related_listing_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
    v_prefs RECORD;
BEGIN
    -- Check user preferences
    SELECT * INTO v_prefs
    FROM notification_preferences
    WHERE user_id = p_user_id;
    
    -- If no preferences exist, create defaults
    IF NOT FOUND THEN
        INSERT INTO notification_preferences (user_id)
        VALUES (p_user_id)
        RETURNING * INTO v_prefs;
    END IF;
    
    -- Check if notifications are enabled
    IF NOT v_prefs.all_notifications THEN
        RETURN NULL;
    END IF;
    
    -- Create notification
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        action_url,
        related_user_id,
        related_order_id,
        related_listing_id,
        metadata
    ) VALUES (
        p_user_id,
        p_type,
        p_title,
        p_message,
        p_action_url,
        p_related_user_id,
        p_related_order_id,
        p_related_listing_id,
        p_metadata
    ) RETURNING id INTO v_notification_id;
    
    -- Queue for email/push delivery based on preferences
    -- This would trigger edge functions or external services
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(
    p_notification_ids UUID[]
)
RETURNS INTEGER AS $$
DECLARE
    rows_updated INTEGER;
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = NOW()
    WHERE id = ANY(p_notification_ids)
    AND user_id = auth.uid()
    AND is_read = FALSE;
    
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RETURN rows_updated;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN COUNT(*)
    FROM notifications
    WHERE user_id = p_user_id
    AND is_read = FALSE
    AND expires_at > NOW();
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger to create notifications on various events
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_title TEXT;
    v_message TEXT;
    v_notify_user UUID;
BEGIN
    -- Skip if status hasn't changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- Determine who to notify and message
    CASE NEW.status
        WHEN 'paid' THEN
            v_notify_user := NEW.seller_id;
            v_title := 'New Order Received!';
            v_message := 'You have a new order #' || NEW.order_number;
            
        WHEN 'shipped' THEN
            v_notify_user := NEW.buyer_id;
            v_title := 'Order Shipped!';
            v_message := 'Your order #' || NEW.order_number || ' has been shipped';
            
        WHEN 'delivered' THEN
            v_notify_user := NEW.buyer_id;
            v_title := 'Order Delivered!';
            v_message := 'Your order #' || NEW.order_number || ' has been delivered';
            
        WHEN 'cancelled' THEN
            -- Notify both parties
            PERFORM create_notification(
                NEW.buyer_id,
                'order_cancelled',
                'Order Cancelled',
                'Order #' || NEW.order_number || ' has been cancelled',
                '/orders/' || NEW.id,
                related_order_id := NEW.id
            );
            
            v_notify_user := NEW.seller_id;
            v_title := 'Order Cancelled';
            v_message := 'Order #' || NEW.order_number || ' has been cancelled';
            
        ELSE
            RETURN NEW;
    END CASE;
    
    -- Create notification
    IF v_notify_user IS NOT NULL THEN
        PERFORM create_notification(
            v_notify_user,
            CASE NEW.status
                WHEN 'paid' THEN 'order_paid'
                WHEN 'shipped' THEN 'order_shipped'
                WHEN 'delivered' THEN 'order_delivered'
                WHEN 'cancelled' THEN 'order_cancelled'
            END::notification_type,
            v_title,
            v_message,
            '/orders/' || NEW.id,
            related_order_id := NEW.id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for order notifications
CREATE TRIGGER notify_on_order_status
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_status_change();

-- Trigger for new message notifications
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
    v_recipient_id UUID;
    v_sender_name TEXT;
    v_conversation RECORD;
BEGIN
    -- Get conversation details
    SELECT * INTO v_conversation
    FROM conversations
    WHERE id = NEW.conversation_id;
    
    -- Determine recipient
    IF NEW.sender_id = v_conversation.buyer_id THEN
        v_recipient_id := v_conversation.seller_id;
    ELSE
        v_recipient_id := v_conversation.buyer_id;
    END IF;
    
    -- Get sender name
    SELECT username INTO v_sender_name
    FROM profiles
    WHERE id = NEW.sender_id;
    
    -- Create notification
    PERFORM create_notification(
        v_recipient_id,
        'new_message',
        'New message from ' || v_sender_name,
        LEFT(NEW.message_text, 100) || CASE WHEN LENGTH(NEW.message_text) > 100 THEN '...' ELSE '' END,
        '/messages/' || NEW.conversation_id,
        related_user_id := NEW.sender_id,
        related_message_id := NEW.id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for message notifications
CREATE TRIGGER notify_on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message();

-- Insert default notification templates
INSERT INTO notification_templates (type, title_template, message_template, variables) VALUES
    ('order_placed', 'New Order: {{order_number}}', 'You have received a new order from {{buyer_name}}', '["order_number", "buyer_name"]'),
    ('order_paid', 'Payment Received!', 'Payment confirmed for order {{order_number}}', '["order_number", "amount"]'),
    ('order_shipped', 'Order Shipped!', 'Your order {{order_number}} is on its way', '["order_number", "tracking_number"]'),
    ('order_delivered', 'Order Delivered', 'Your order {{order_number}} has been delivered', '["order_number"]'),
    ('new_message', 'New message from {{sender_name}}', '{{message_preview}}', '["sender_name", "message_preview"]'),
    ('new_rating', '{{rater_name}} left you a review', '{{rating}} stars: {{review_text}}', '["rater_name", "rating", "review_text"]'),
    ('new_follower', '{{follower_name}} started following you', 'You have a new follower!', '["follower_name"]'),
    ('listing_favorited', '{{user_name}} favorited your item', '{{listing_title}} was added to favorites', '["user_name", "listing_title"]'),
    ('price_drop', 'Price dropped on {{listing_title}}', 'Now only {{new_price}} (was {{old_price}})', '["listing_title", "new_price", "old_price"]')
ON CONFLICT (type) DO NOTHING;

-- Function to clean up old notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
    WHERE expires_at < NOW()
    OR (is_read = TRUE AND created_at < NOW() - INTERVAL '7 days');
END;
$$ LANGUAGE plpgsql;