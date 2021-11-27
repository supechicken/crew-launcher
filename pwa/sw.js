// sw.js: Service Worker script

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open('v1').then( (cache) => {
      return cache.add('failed.html');
    })
  );
});

self.addEventListener('fetch', (req) => {
  req.respondWith(fetch(e.request.url)).catch (e) {
    console.err('connection error: ', e);
    return caches.match('failed.html');
  }
});
