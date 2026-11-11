/* Kofvi ADHD Life Planner: offline support. The page is network-first (always the newest version when online),
   with the last copy kept for offline use. Supabase API calls are never cached. */
const CACHE = "kofvi-adhd-v1";
const CORE = ["./", "manifest.webmanifest", "icon-192.png", "/planner/config.js",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).catch(() => {})); self.skipWaiting(); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET" || /supabase\.co$/.test(u.hostname)) return;
  if (r.mode === "navigate" || u.pathname.endsWith("/planner/adhd/") || u.pathname.endsWith("/planner/adhd/index.html") || u.pathname === "/planner/config.js") {
    e.respondWith(fetch(r).then(res => { const c = res.clone(); caches.open(CACHE).then(x => x.put(r.mode === "navigate" ? "./" : r, c)); return res; })
      .catch(() => caches.match(r.mode === "navigate" ? "./" : r).then(m => m || caches.match("./"))));
    return;
  }
  if (/fonts\.(googleapis|gstatic)\.com$/.test(u.hostname) || u.hostname === "cdn.jsdelivr.net" || u.origin === location.origin) {
    e.respondWith(caches.match(r).then(m => m || fetch(r).then(res => { if (res.ok || res.type === "opaque") { const c = res.clone(); caches.open(CACHE).then(x => x.put(r, c)); } return res; })));
  }
});
/* Tapping a reminder opens (or focuses) the planner */
self.addEventListener("notificationclick", e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(cs => {
    for (const c of cs) if (c.url.includes("/planner/adhd/")) return c.focus();
    return self.clients.openWindow("/planner/adhd/#home");
  }));
});
/* Ready for real push reminders later (server sends them even when the app is closed) */
self.addEventListener("push", e => {
  let d = {}; try { d = e.data ? e.data.json() : {}; } catch (_) { d = { title: "Kofvi", body: e.data && e.data.text() }; }
  e.waitUntil(self.registration.showNotification(d.title || "Kofvi Planner", { body: d.body || "", icon: "icon-192.png", badge: "icon-192.png", tag: d.tag }));
});
