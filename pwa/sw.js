// sw.js: Service Worker script

self.addEventListener('fetch', (req) => {
  try {
    fetch(e.request.url).then( (e) => {
      req.respondWith(e.blob);
    });
  } catch (e) {
    console.err('connection error: ', e);
    req.respondWith(`
<html>
  <style>
    html, body {
      height: 100%;
    }

    body {
      background-color: white;
      color: black;
      font-size: 20px;
      font-family: Arial;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }
    
    h1, h2, h3 {
      font-family: Arial;
    }
  </style>
  <body>
    <h1>Cannot connect to host!</h1>
    <h2>Please check if the launcher daemon is started correctly</h2>
  </body>
</html>
`)});
