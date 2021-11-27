// sw.js: Service Worker script

self.addEventListener('fetch', (req) => {
  req.respondWith(fetch(e.request.url)).catch (e) {
    console.err('connection error: ', e);
    return caches.match('offline.html');
  }
});
