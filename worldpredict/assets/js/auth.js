// Supabase Client
const SUPABASE_URL = 'https://nfvkxdgcfqakfvzbwnyh.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ZYCsRSUnTyd49_BtlPnI4Q_M6KY20Qd';

const supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

let currentUser = null;

// Init current user
async function getCurrentUser() {
  const { data: { session } } = await supabase.auth.getSession();
  if (session) {
    currentUser = await getUserProfile(session.user.id);
  }
  return currentUser;
}

// Signup logic
async function signup(username, email, password, role, parentChildCode = null) {
  // Create auth user
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { username, role } }
  });
  
  if (error) throw new Error(error.message);
  
  const userId = data.user.id;
  
  // Insert user profile
  const { error: profileError } = await supabase
    .from('users')
    .insert({ 
      id: userId, 
      email, 
      username, 
      role,
      child_code: role === 'user' ? generateChildCode() : null 
    });
  
  if (profileError) throw new Error(profileError.message);
  
  // If parent, link to child
  if (role === 'parent' && parentChildCode) {
    await linkParentToChild(data.user.id, parentChildCode);
  }
  
  // Log activity
  await logActivity(userId, 'signup', { role });
  
  return data;
}

// Login
async function login(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  
  currentUser = await getUserProfile(data.user.id);
  await logActivity(data.user.id, 'login', { device: navigator.userAgent });
  
  return { role: currentUser.role };
}

// Get user profile with role
async function getUserProfile(userId) {
  const { data } = await supabase
    .from('users')
    .select('username, role, child_code')
    .eq('id', userId)
    .single();
  
  if (data) {
    data.username = data.username || supabase.auth.getUser().user.user_metadata.username;
  }
  
  return data;
}

// Generate 8-char child code
function generateChildCode() {
  return Math.random().toString(36).substring(2, 10).toUpperCase();
}

// Link parent-child
async function linkParentToChild(parentId, childCode) {
  // Get child by code
  const { data: child } = await supabase
    .from('users')
    .select('id')
    .eq('child_code', childCode)
    .single();
    
  if (!child) throw new Error('Invalid child code');
  
  const { error } = await supabase
    .from('parent_child_links')
    .insert({ parent_id: parentId, child_id: child.id });
    
  if (error) throw error;
}

// Logout
async function logout() {
  await supabase.auth.signOut();
  currentUser = null;
  window.location.href = 'index.html';
}

// Activity log
async function logActivity(userId, type, details) {
  await supabase
    .from('activity_logs')
    .insert({ 
      user_id: userId, 
      activity_type: type, 
      details,
      created_at: new Date().toISOString() 
    });
}

