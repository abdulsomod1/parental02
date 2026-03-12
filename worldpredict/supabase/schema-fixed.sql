-- WorldPredict Database Schema (Fixed)
-- Run this in Supabase SQL Editor AFTER dropping existing tables if needed

-- Users table (auto-populate via trigger)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL,
  role TEXT CHECK (role IN ('user', 'parent')) NOT NULL DEFAULT 'user',
  child_code TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Parent-child links
CREATE TABLE IF NOT EXISTS parent_child_links (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(parent_id, child_id)
);

-- Predictions
CREATE TABLE IF NOT EXISTS predictions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  topic TEXT NOT NULL,
  prediction TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity logs
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_child_code ON users(child_code);
CREATE INDEX IF NOT EXISTS idx_predictions_user ON predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_time ON activity_logs(created_at);

-- Simplified child_code trigger (8-char upper like JS)
CREATE OR REPLACE FUNCTION generate_child_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'user' AND NEW.child_code IS NULL THEN
    NEW.child_code := upper(substring(md5(random()::text), 1, 8));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_child_code ON users;
CREATE TRIGGER trg_generate_child_code
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION generate_child_code();

-- Fixed trigger for new auth users (use options.data)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, role)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.user_metadata->>'username', 'Anonymous'), COALESCE((NEW.user_metadata->>'role')::text, 'user'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

