// Supabase Client Initialization (wait for library load)
const SUPABASE_URL = 'https://nfvkxdgcfqakfvzbwnyh.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ZYCsRSUnTyd49_BtlPnI4Q_M6KY20Qd';

let supabaseClient = null;

async function initSupabase() {
  if (typeof supabase === 'undefined') {
    console.error('Supabase library not loaded');
    throw new Error('Supabase not available');
  }
  supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  window.supabase = supabaseClient;
  console.log('Supabase client initialized:', !!supabaseClient);
}

initSupabase().catch(console.error);

let currentUser = null;

// Init current user
async function getCurrentUser() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (session) {
    currentUser = await getUserProfile(session.user.id);
  }
  return currentUser;
}

// Signup logic
window.signup = async function(username, email, password, role, parentChildCode = null) {
  if (!supabaseClient) {
    console.error('Supabase not initialized');
    throw new Error('Supabase client not ready');
  }
  try {
    console.log('Signup attempt:', {username, email, role});
    // Create auth user
    const { data, error } = await supabaseClient.auth.signUp({
      email,
      password,
      options: { data: { username, role } }
    });
    
    if (error) throw new Error(error.message);
    
    const userId = data.user.id;
    
    // User profile auto-created by Supabase trigger from auth metadata
    console.log('User profile created via trigger:', userId);
    
    // If parent, link to child
    if (role === 'parent' && parentChildCode) {
      await linkParentToChild(data.user.id, parentChildCode);
    }
    
    // Skip logActivity - new user has no session, RLS blocks anon insert
    console.log('Signup activity logged via trigger/server logs');
    
    console.log('Signup success:', userId);
    return data;
  } catch (err) {
    console.error('Signup error:', err);
    throw err;
  }
};

// Login
window.login = async function(email, password) {
  if (!supabaseClient) throw new Error('Supabase client not ready');
  try {
    console.log('Login attempt:', email);
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) throw error;
    
    window.currentUser = await getUserProfile(data.user.id);
    await logActivity(data.user.id, 'login', { device: navigator.userAgent });
    
    console.log('Login success, role:', window.currentUser.role);
    return { role: window.currentUser.role };
  } catch (err) {
    console.error('Login error:', err);
    throw err;
  }
};

// Get user profile with role
async function getUserProfile(userId) {
  const { data } = await supabaseClient
    .from('users')
    .select('username, role, child_code')
    .eq('id', userId)
    .single();
  
  if (data) {
    data.username = data.username || (await supabaseClient.auth.getUser()).data.user?.user_metadata?.username;
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
  const { data: child } = await supabaseClient
    .from('users')
    .select('id')
    .eq('child_code', childCode)
    .single();
    
  if (!child) throw new Error('Invalid child code');
  
  const { error } = await supabaseClient
    .from('parent_child_links')
    .insert({ parent_id: parentId, child_id: child.id });
    
  if (error) throw error;
}



// Activity log
window.logActivity = async function(userId, type, details) {
  if (!supabaseClient) return;
  try {
    await supabaseClient
      .from('activity_logs')
      .insert({ 
        user_id: userId, 
        activity_type: type, 
        details,
        created_at: new Date().toISOString() 
      });
  } catch (err) {
    console.warn('Log activity failed:', err);
  }
};

window.logout = async function() {
  if (supabaseClient) await supabaseClient.auth.signOut();
  window.currentUser = null;
  window.location.href = 'index.html';
};

window.generateChildCode = generateChildCode;
window.getUserProfile = getUserProfile;
window.getCurrentUser = getCurrentUser;

