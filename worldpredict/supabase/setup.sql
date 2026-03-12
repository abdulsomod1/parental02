-- WorldPredict Complete Supabase Setup (Run ALL in SQL Editor)
-- Fixes auth.signup 500 + DB errors

-- 1. Enable required extensions (if needed)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Drop all custom tables/triggers (reset)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trg_generate_child_code ON users;
DROP TABLE IF EXISTS users, parent_child_links, predictions, activity_logs CASCADE;

-- 3. Recreate tables (schema-fixed)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL,
  role TEXT CHECK (role IN ('user', 'parent')) NOT NULL DEFAULT 'user',
  child_code TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE parent_child_links (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(parent_id, child_id)
);

CREATE TABLE predictions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  topic TEXT NOT NULL,
  prediction TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE activity_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_child_code ON users(child_code);
CREATE INDEX idx_predictions_user ON predictions(user_id);
CREATE INDEX idx_activity_user ON activity_logs(user_id);

-- 4. Triggers
CREATE OR REPLACE FUNCTION generate_child_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'user' AND NEW.child_code IS NULL THEN
    NEW.child_code := upper(substring(md5(random()::text), 1, 8));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_child_code BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION generate_child_code();

-- Fixed trigger for auth.signup metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, role)
  VALUES (NEW.id, NEW.email, COALESCE((NEW.user_metadata->>'username')::text, 'Anonymous'), COALESCE((NEW.user_metadata->>'role')::text, 'user'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 5. RLS (rls-fixed)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_child_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Parents view child" ON users FOR SELECT USING (auth.uid() = id OR id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid()));

CREATE POLICY "Parents links" ON parent_child_links FOR ALL USING (auth.uid() = parent_id);
CREATE POLICY "Predictions own RW" ON predictions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Predictions parents read" ON predictions FOR SELECT USING (user_id = auth.uid() OR user_id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid()));

CREATE POLICY "Logs own read" ON activity_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Logs parents read" ON activity_logs FOR SELECT USING (user_id = auth.uid() OR user_id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid()));

-- Success: Run script, test signup.html (no test INSERT needed)
-- Dashboard > Authentication > Settings > Enable Email + localhost redirects
