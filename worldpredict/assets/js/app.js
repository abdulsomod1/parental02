// App utilities and simple SPA routing

// Import Supabase (CDN handled in HTML)


let currentUser = null;

async function initApp() {
  await getCurrentUser();
}

async function getCurrentUser() {
  const { data: { session } } = await supabase.auth.getSession();
  if (session) {
    currentUser = await getUserProfile(session.user.id); // from auth.js
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

// Auto-protect dashboards
if (window.location.pathname.includes('dashboard') && !currentUser) {
  window.location.href = 'login.html';
}

