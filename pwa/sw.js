// sw.js: Service Worker script
// add error page to cache
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open('v1').then( (cache) => {
      return cache.add('failed.html');
    })
  );
});

// show error page if it failed to connect to the daemon
self.addEventListener('fetch', (req) => {
  req.respondWith(fetch(req.request.url).catch((e) => {
    console.error('connection error: ', e);
    return caches.match('failed.html');
  }));
});
