// App utilities and simple SPA routing - uses global auth from auth.js

let currentUser = window.currentUser || null;

async function initApp() {
  if (typeof window.getCurrentUser === 'function') {
    currentUser = await window.getCurrentUser();
  }
}

async function getCurrentUser() {
  if (!window.supabase) {
    console.warn('Supabase not ready');
    return null;
  }
  const { data: { session } } = await window.supabase.auth.getSession();
  if (session) {
    if (typeof window.getUserProfile === 'function') {
      currentUser = await window.getUserProfile(session.user.id);
    }
  }
  return currentUser;
}

// Simple client-side routing
function router(path) {
  const pages = {
    '/': 'index.html',
    '/user-dashboard': 'user-dashboard.html',
    '/parent-dashboard': 'parent-dashboard.html'
  };
  // Netlify handles most routing
}

// Auto-protect dashboards (async check)
(async () => {
  if (window.location.pathname.includes('dashboard')) {
    await getCurrentUser();
    if (!currentUser) {
      window.location.href = 'login.html';
    }
  }
})();

// Auto init app
initApp();

