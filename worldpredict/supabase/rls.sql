-- Row Level Security Policies
-- Enable RLS first: ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Users RLS (users see own profile, parents see their child)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Parents can view their child profile" ON users
  FOR SELECT USING (
    auth.uid() = id OR 
    id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid())
  );

-- Parent-child links RLS
ALTER TABLE parent_child_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents manage own links" ON parent_child_links
  FOR ALL USING (auth.uid() = parent_id);

-- Predictions RLS
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view/modify own predictions" ON predictions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Parents view child predictions" ON predictions
  FOR SELECT USING (
    user_id = auth.uid() OR 
    user_id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid())
  );

-- Activity logs RLS
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own logs" ON activity_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Parents view child logs" ON activity_logs
  FOR SELECT USING (
    user_id = auth.uid() OR 
    user_id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid())
  );

-- Public anon access for app (limited)
CREATE POLICY "Enable read access for authenticated users" ON users
  FOR SELECT USING (auth.role() = 'authenticated');
