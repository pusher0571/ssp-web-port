const helpDialog = document.getElementById('help');
const creditsDialog = document.getElementById('credits');
document.getElementById('how-to-play').onclick = () => helpDialog.showModal();
document.getElementById('show-credits').onclick = () => creditsDialog.showModal();
document.getElementById('close-credits').onclick = () => creditsDialog.close();
for (const dialog of [helpDialog, creditsDialog]) {
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const rect = dialog.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
  });
}
const motionPreference = matchMedia('(prefers-reduced-motion: reduce)');
const menuScene = document.querySelector('.menu-scene');
let driftFrame = 0;
window.addEventListener('pointermove', event => {
  if (!document.body.classList.contains('pregame') || motionPreference.matches || event.pointerType !== 'mouse') return;
  cancelAnimationFrame(driftFrame);
  driftFrame = requestAnimationFrame(() => {
    menuScene.style.setProperty('--drift-x', `${(event.clientX / innerWidth - .5) * 12}px`);
    menuScene.style.setProperty('--drift-y', `${(event.clientY / innerHeight - .5) * 8}px`);
  });
}, { passive: true });
