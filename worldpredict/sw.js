const CACHE_NAME = 'worldpredict-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/signup.html',
  '/login.html',
  '/user-dashboard.html',
  '/parent-dashboard.html',
  '/assets/css/styles.css',
  '/assets/js/app.js',
  '/assets/js/auth.js',
  '/assets/js/predictions.js',
  '/manifest.json'
];

// Install
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

// Fetch
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});

// Background sync
self.addEventListener('sync', event => {
  if (event.tag === 'sync-predictions') {
    event.waitUntil(syncPendingPredictions());
  }
});

async function syncPendingPredictions() {
  // Implement pending queue sync with IndexedDB
  console.log('Background sync triggered');
}
