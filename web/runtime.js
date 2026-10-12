const gameCanvas = document.getElementById('canvas');
const captureOverlay = document.getElementById('capture-overlay');
const captureStatus = document.getElementById('capture-status');
let gameActive = false;

window.sspSetGameActive = active => {
  gameActive = active;
  captureOverlay.hidden = !active || document.pointerLockElement === gameCanvas;
  if (!active && document.pointerLockElement === gameCanvas) document.exitPointerLock();
};
function updatePointer() {
  const locked = document.pointerLockElement === gameCanvas;
  gameCanvas.dataset.pointerLocked = String(locked);
  captureOverlay.hidden = !gameActive || locked;
  if (window.sspPointerCallback) window.sspPointerCallback(locked);
}
async function captureMouse() {
  if (!gameActive) return;
  captureStatus.textContent = 'ESC pausiert das Spiel und gibt die Maus frei.';
  gameCanvas.focus();
  try { await gameCanvas.requestPointerLock(); }
  catch { captureStatus.textContent = 'Mausfreigabe fehlgeschlagen. Bitte erneut klicken oder in Chrome/Edge öffnen.'; }
}
document.getElementById('capture-button').onclick = captureMouse;
document.getElementById('leave-game').onclick = () => { if (window.sspExitCallback) window.sspExitCallback(); };
document.addEventListener('pointerlockchange', updatePointer);
document.addEventListener('pointerlockerror', () => {
  captureStatus.textContent = 'Der Browser hat den Mausfang abgelehnt. Bitte direkt klicken; falls es weiter scheitert, den Spiel-Link in Chrome, Edge oder Firefox öffnen.';
});
document.addEventListener('keydown', event => {
  if (gameActive && document.pointerLockElement !== gameCanvas && event.code === 'Space') {
    event.preventDefault(); captureMouse();
  }
});
window.addEventListener('blur', () => {
  if (document.pointerLockElement === gameCanvas) document.exitPointerLock();
});

// GitHub Pages cannot set these HTTP headers directly. The scoped worker adds
// them to same-origin responses so Godot can mix audio on its own thread.
window.sspEnsureIsolation = async () => {
  if (window.crossOriginIsolated) return true;
  if (!window.isSecureContext || !('serviceWorker' in navigator)) {
    throw new Error('Dieser Browser unterstützt die Audio-Ausgabe nicht. Bitte die HTTPS-Seite in Chrome, Edge oder Firefox öffnen.');
  }
  await navigator.serviceWorker.register('isolation-worker.js', { scope: './', updateViaCache: 'none' });
  await navigator.serviceWorker.ready;
  // A document must be loaded through the worker to receive isolation headers.
  if (!navigator.serviceWorker.controller) {
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Browser-Freigabe dauert zu lange. Bitte Seite neu laden.')), 10000);
      navigator.serviceWorker.addEventListener('controllerchange', () => { clearTimeout(timer); resolve(); }, { once: true });
    });
  }
  if (sessionStorage.getItem('ssp-isolation-reload') === 'pending') {
    throw new Error('Dieser Browser verhindert die Audio-Freigabe. Bitte den Spiel-Link in Chrome, Edge oder Firefox öffnen.');
  }
  sessionStorage.setItem('ssp-isolation-reload', 'pending');
  location.reload();
  return false;
};
if (window.crossOriginIsolated) sessionStorage.removeItem('ssp-isolation-reload');
