-- WorldPredict Schema Verification (Run in Supabase SQL Editor)
-- Confirms tables/triggers/RLS active

-- 1. Check tables exist
SELECT 'Users table OK' as status FROM users WHERE FALSE
UNION ALL
SELECT 'Parent links OK' FROM parent_child_links WHERE FALSE
UNION ALL
SELECT 'Predictions OK' FROM predictions WHERE FALSE
UNION ALL
SELECT 'Activity OK' FROM activity_logs WHERE FALSE;

-- 2. Test auth trigger (creates test user - DELETE after)
-- INSERT INTO auth.users (id, email, user_metadata) VALUES (gen_random_uuid(), 'test@test.com', '{"username": "test", "role": "user"}'); -- MANUAL ONLY if needed

-- 3. Check RLS status
SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename IN ('users', 'parent_child_links', 'predictions', 'activity_logs');

-- 4. List triggers
SELECT event_object_table, trigger_name, action_timing, event_manipulation 
FROM information_schema.triggers 
WHERE event_object_schema = 'public';

-- 5. Check Email auth enabled (requires dashboard check)
SELECT 'Email auth manual check: Dashboard > Auth > Settings > Email ON?' as note;

-- Success = All tables listed, RLS=true, triggers present
-- Test signup.html
