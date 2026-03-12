-- Row Level Security Policies (Fixed/Cleaned)
-- Assume RLS enabled on tables

-- Users RLS
CREATE POLICY "Users view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Parents view child profile" ON users FOR SELECT USING (
  auth.uid() = id OR 
  id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid())
);

-- Parent-child links
CREATE POLICY "Parents manage links" ON parent_child_links FOR ALL USING (auth.uid() = parent_id);

-- Predictions
CREATE POLICY "Own predictions RW" ON predictions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Parents read child predictions" ON predictions FOR SELECT USING (
  user_id = auth.uid() OR 
  user_id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid())
);

-- Activity logs
CREATE POLICY "Own logs read" ON activity_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Parents read child logs" ON activity_logs FOR SELECT USING (
  user_id = auth.uid() OR 
  user_id IN (SELECT child_id FROM parent_child_links WHERE parent_id = auth.uid())
);

