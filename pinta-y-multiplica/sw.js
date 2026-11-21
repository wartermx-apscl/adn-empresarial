/* Pinta y Multiplica: guarda una copia del juego en la tablet para que abra rápido y funcione sin internet.
   La página siempre se pide primero a internet, así que cuando subas una versión nueva se actualiza sola. */
var CACHE = 'pinta-y-multiplica-v2';
var CORE = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE)
      .then(function (c) { return Promise.all(CORE.map(function (u) { return c.add(u).catch(function () {}); })); })
      .then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys()
      .then(function (keys) { return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); })); })
      .then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);

  // La página: primero internet (para recibir versiones nuevas); si no hay, la copia guardada.
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(function (res) { var copy = res.clone(); caches.open(CACHE).then(function (c) { c.put('./', copy); }); return res; })
        .catch(function () { return caches.match('./').then(function (m) { return m || caches.match('./index.html'); }); })
    );
    return;
  }

  // Íconos, manifiesto y letras: la copia guardada al instante y se renueva por detrás.
  var sameOrigin = url.origin === self.location.origin;
  var fonts = url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com';
  if (!sameOrigin && !fonts) return;
  e.respondWith(
    caches.match(req).then(function (cached) {
      var net = fetch(req).then(function (res) {
        if (res && (res.ok || res.type === 'opaque')) { var copy = res.clone(); caches.open(CACHE).then(function (c) { c.put(req, copy); }); }
        return res;
      }).catch(function () { return cached; });
      return cached || net;
    })
  );
});
