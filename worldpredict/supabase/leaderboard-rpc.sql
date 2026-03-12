-- Leaderboard RPC for top 10 users by prediction count
-- Run in Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_leaderboard()
RETURNS TABLE (
  username text,
  prediction_count bigint
) 
LANGUAGE sql 
SECURITY DEFINER
AS $$
  SELECT u.username, COUNT(p.id) as prediction_count
  FROM users u
  LEFT JOIN predictions p ON u.id = p.user_id
  GROUP BY u.id, u.username
  ORDER BY prediction_count DESC NULLS LAST
  LIMIT 10;
$$;

