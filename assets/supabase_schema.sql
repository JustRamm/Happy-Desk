-- ==========================================
-- HAPPY DESK SUPABASE DATABASE SCHEMA (COMPLETE)
-- ==========================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create Companies Table
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    company_code TEXT UNIQUE NOT NULL,
    founder_id UUID,
    hq_location TEXT DEFAULT '',
    industry TEXT DEFAULT '',
    company_size TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Profiles Table (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    name TEXT NOT NULL,
    role_type TEXT NOT NULL CHECK (role_type IN ('founder', 'employee')),
    is_leader BOOLEAN DEFAULT FALSE,
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    job_title TEXT DEFAULT 'Employee',
    department TEXT DEFAULT 'General',
    bio TEXT DEFAULT '',
    strengths TEXT DEFAULT '',
    focus_area TEXT DEFAULT '',
    current_challenges TEXT DEFAULT '',
    communication_preference TEXT DEFAULT '',
    avatar_url TEXT DEFAULT 'assets/avatars/user_avatar.png',
    fcm_token TEXT DEFAULT '',
    is_clocked_in BOOLEAN DEFAULT FALSE,
    is_on_break BOOLEAN DEFAULT FALSE,
    last_clock_in_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add founder_id FK to companies
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_companies_founder'
    ) THEN
        ALTER TABLE public.companies 
        ADD CONSTRAINT fk_companies_founder 
        FOREIGN KEY (founder_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 4. Company Join Codes Table
CREATE TABLE IF NOT EXISTS public.company_join_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    role_tag TEXT NOT NULL CHECK (role_tag IN ('employee', 'leader')),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Work Sessions Table
CREATE TABLE IF NOT EXISTS public.work_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    clock_in_time TIMESTAMPTZ NOT NULL,
    clock_out_time TIMESTAMPTZ,
    total_break_minutes INT DEFAULT 0,
    clock_in_lat DOUBLE PRECISION,
    clock_in_lng DOUBLE PRECISION,
    clock_in_location_name TEXT,
    clock_in_country TEXT DEFAULT '',
    clock_in_state TEXT DEFAULT '',
    clock_in_district TEXT DEFAULT '',
    clock_in_pincode TEXT DEFAULT '',
    clock_out_lat DOUBLE PRECISION,
    clock_out_lng DOUBLE PRECISION,
    clock_out_location_name TEXT DEFAULT '',
    clock_out_country TEXT DEFAULT '',
    clock_out_state TEXT DEFAULT '',
    clock_out_district TEXT DEFAULT '',
    clock_out_pincode TEXT DEFAULT '',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_break', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Leave Requests Table
CREATE TABLE IF NOT EXISTS public.leave_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    leave_type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Coffee Break Invites Table
CREATE TABLE IF NOT EXISTS public.coffee_break_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_group BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. NGL Jar Messages Table (Anonymous Venting Jar)
CREATE TABLE IF NOT EXISTS public.ngl_jar_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT TRUE,
    likes_count INT DEFAULT 0,
    tag TEXT DEFAULT 'vent',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Weekly Hero Nominations Table
CREATE TABLE IF NOT EXISTS public.weekly_hero_nominations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nominee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    nominee_name TEXT NOT NULL,
    nominator_name TEXT NOT NULL,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    badge_type TEXT DEFAULT 'Coffee Hero',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Mochi Per-Timestamp Chat Messages Table
CREATE TABLE IF NOT EXISTS public.mochi_chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_user BOOLEAN DEFAULT TRUE,
    action_type TEXT,
    session_id UUID DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Mochi Session Summaries Table
CREATE TABLE IF NOT EXISTS public.mochi_session_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    summary_text TEXT NOT NULL,
    total_turns INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Direct Messages Table (Teammate Chat)
CREATE TABLE IF NOT EXISTS public.direct_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_name TEXT NOT NULL,
    message TEXT NOT NULL,
    media_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. Team Broadcast Feed Table
CREATE TABLE IF NOT EXISTS public.team_broadcast_feed (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. Mochi Mood Logs Table
CREATE TABLE IF NOT EXISTS public.mochi_mood_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    score INT NOT NULL,
    label TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. Mochi CBT Logs Table
CREATE TABLE IF NOT EXISTS public.mochi_cbt_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    trigger TEXT NOT NULL,
    distortion_tag TEXT NOT NULL,
    pre_score INT NOT NULL,
    post_score INT NOT NULL,
    reframe_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. Call Invites Table (Audio / Video Calls)
CREATE TABLE IF NOT EXISTS public.call_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    caller_name TEXT NOT NULL,
    is_video BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'ringing' CHECK (status IN ('ringing', 'accepted', 'rejected', 'ended')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_join_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coffee_break_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ngl_jar_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_hero_nominations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mochi_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mochi_session_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_broadcast_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mochi_mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mochi_cbt_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_invites ENABLE ROW LEVEL SECURITY;

-- 18. Create Permissive RLS Policies
DROP POLICY IF EXISTS "Public Profiles access" ON public.profiles;
CREATE POLICY "Public Profiles access" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Companies access" ON public.companies;
CREATE POLICY "Public Companies access" ON public.companies FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Join Codes access" ON public.company_join_codes;
CREATE POLICY "Public Join Codes access" ON public.company_join_codes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Work Sessions access" ON public.work_sessions;
CREATE POLICY "Public Work Sessions access" ON public.work_sessions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Leave Requests access" ON public.leave_requests;
CREATE POLICY "Public Leave Requests access" ON public.leave_requests FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Coffee Invites access" ON public.coffee_break_invites;
CREATE POLICY "Public Coffee Invites access" ON public.coffee_break_invites FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public NGL Jar access" ON public.ngl_jar_messages;
CREATE POLICY "Public NGL Jar access" ON public.ngl_jar_messages FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Weekly Hero access" ON public.weekly_hero_nominations;
CREATE POLICY "Public Weekly Hero access" ON public.weekly_hero_nominations FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Mochi Chat access" ON public.mochi_chat_messages;
CREATE POLICY "Public Mochi Chat access" ON public.mochi_chat_messages FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Mochi Summaries access" ON public.mochi_session_summaries;
CREATE POLICY "Public Mochi Summaries access" ON public.mochi_session_summaries FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Direct Messages access" ON public.direct_messages;
CREATE POLICY "Public Direct Messages access" ON public.direct_messages FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Team Broadcast access" ON public.team_broadcast_feed;
CREATE POLICY "Public Team Broadcast access" ON public.team_broadcast_feed FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Mood Logs access" ON public.mochi_mood_logs;
CREATE POLICY "Public Mood Logs access" ON public.mochi_mood_logs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public CBT Logs access" ON public.mochi_cbt_logs;
CREATE POLICY "Public CBT Logs access" ON public.mochi_cbt_logs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public Call Invites access" ON public.call_invites;
CREATE POLICY "Public Call Invites access" ON public.call_invites FOR ALL USING (true) WITH CHECK (true);

-- 18. Storage Buckets Setup
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('chat_attachments', 'chat_attachments', true) ON CONFLICT (id) DO NOTHING;

-- 19. Enable Realtime Publications
ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_broadcast_feed;
ALTER PUBLICATION supabase_realtime ADD TABLE public.coffee_break_invites;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ngl_jar_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.call_invites;

-- 20. Seed Initial Prototype Data
INSERT INTO public.companies (id, name, company_code) 
VALUES ('11111111-1111-1111-1111-111111111111', 'U & ME HQ', 'COMP-DEMO') 
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.company_join_codes (company_id, code, role_tag)
VALUES ('11111111-1111-1111-1111-111111111111', 'LEAD-9999', 'leader')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.company_join_codes (company_id, code, role_tag)
VALUES ('11111111-1111-1111-1111-111111111111', 'EMP-1111', 'employee')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.ngl_jar_messages (company_id, message, is_anonymous, likes_count, tag)
VALUES 
('11111111-1111-1111-1111-111111111111', 'Honestly, taking a 5-minute break outside saved my sanity today. Don''t forget to step away from your screens!', true, 12, 'wellbeing'),
('11111111-1111-1111-1111-111111111111', 'Shoutout to the design team for staying calm through 3 client pivots this morning!', true, 8, 'appreciation'),
('11111111-1111-1111-1111-111111111111', 'Back-to-back 4-hour meeting blocks should be illegal on Fridays.', true, 19, 'vent');

INSERT INTO public.weekly_hero_nominations (nominee_name, nominator_name, company_id, reason, badge_type)
VALUES
('Sarah Chen', 'Rownok Ahmed', '11111111-1111-1111-1111-111111111111', 'Brought coffee and walked me through the design system guidelines so patiently!', 'Coffee Hero'),
('David Kim', 'Alex Chen', '11111111-1111-1111-1111-111111111111', 'Stayed late to unblock the staging pipeline deployment before weekend release.', 'Problem Solver');

INSERT INTO public.team_broadcast_feed (company_id, sender_name, event_type, title, body)
VALUES
('11111111-1111-1111-1111-111111111111', 'Sarah Chen', 'clock_in', 'Sarah Chen Clocked In', 'Sarah Chen clocked in for standard shift at U & ME HQ (Floor 3).'),
('11111111-1111-1111-1111-111111111111', 'Alex Chen', 'leave_approved', 'Leave Approved: Alex Chen', 'Alex Chen''s Casual Leave for Jul 29 – Jul 30 was approved by HR.'),
('11111111-1111-1111-1111-111111111111', 'David Kim', 'hero_win', 'Weekly Hero Shoutout', 'David Kim was nominated as Problem Solver of the Week!');

-- ==========================================
-- SAFE MIGRATION FOR NEW FOUNDER & LOCATION FIELDS
-- ==========================================
DO $$ 
BEGIN
    -- Add hq_location column to companies if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'hq_location') THEN
        ALTER TABLE public.companies ADD COLUMN hq_location TEXT DEFAULT 'New York, USA';
    END IF;

    -- Add industry column to companies if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'industry') THEN
        ALTER TABLE public.companies ADD COLUMN industry TEXT DEFAULT 'Software & Tech';
    END IF;

    -- Add company_size column to companies if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'company_size') THEN
        ALTER TABLE public.companies ADD COLUMN company_size TEXT DEFAULT '11-50 employees';
    END IF;
END $$;
