-- WorldPredict Database Schema
-- Run this in Supabase SQL Editor

-- Enable RLS on auth.users
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL,
  role TEXT CHECK (role IN ('user', 'parent')) NOT NULL,
  child_code TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Parent-child links
CREATE TABLE parent_child_links (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(parent_id, child_id)
);

-- Predictions
CREATE TABLE predictions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  topic TEXT NOT NULL,
  prediction TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity logs
CREATE TABLE activity_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_child_code ON users(child_code);
CREATE INDEX idx_predictions_user ON predictions(user_id);
CREATE INDEX idx_activity_user ON activity_logs(user_id);
CREATE INDEX idx_activity_time ON activity_logs(created_at);

-- Function to generate child_code trigger
CREATE OR REPLACE FUNCTION generate_child_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'user' AND NEW.child_code IS NULL THEN
    NEW.child_code := encode(gen_random_bytes(4), 'hex') || substring(md5(random()::text), 1, 4);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_child_code
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION generate_child_code();

-- Insert user profile after auth signup (trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, role)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'username', NEW.raw_user_meta_data->>'role');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new auth users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
