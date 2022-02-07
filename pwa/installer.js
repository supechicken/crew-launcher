const params = new URLSearchParams(document.location.search);

// set manifest path
let linkElement = document.createElement('link');
linkElement.rel = 'manifest';
linkElement.setAttribute('href', `/installer/manifest.webmanifest?entryFile=${params.get('entryFile')}`);
document.head.appendChild(linkElement);



navigator.serviceWorker.register('./sw.js')
           
self.addEventListener('appinstalled', (event) => {
  // tell socket server to stop
  document.getElementById('installBut').style.visibility = 'hidden';
  document.getElementById('closeMsg').style.visibility = 'visible';
});

self.addEventListener('beforeinstallprompt', (e) => {
  self.InstallPrompt = e
});

installBut.addEventListener('click', () => {
  self.InstallPrompt.prompt();
});
