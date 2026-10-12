(() => {
  const dialog = document.getElementById('settings-codes');
  const exported = document.getElementById('settings-export-code');
  const imported = document.getElementById('settings-import-code');
  const status = document.getElementById('settings-code-status');
  const apply = document.getElementById('settings-code-import');
  const undo = document.getElementById('settings-code-undo');
  const copy = document.getElementById('settings-code-copy');
  const say = (message, error = false) => {
    status.textContent = message;
    status.dataset.error = String(error);
  };
  const busy = value => { apply.disabled = value; undo.disabled = value; };
  const canUndo = value => { undo.hidden = !value; };
  window.sspSettingsCodes = {
    open(code, hasUndo) {
      exported.value = code;
      imported.value = '';
      busy(false);
      canUndo(hasUndo);
      say('Your current settings are ready to share.');
      if (!dialog.open) dialog.showModal();
      exported.scrollTop = 0;
      copy.focus({ preventScroll: true });
      dialog.scrollTop = 0;
    },
    result(message, error, code, hasUndo) {
      busy(false);
      exported.value = code;
      exported.scrollTop = 0;
      canUndo(hasUndo);
      say(message, error);
      if (!error) imported.value = '';
    }
  };
  copy.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(exported.value);
      say('Settings code copied.');
    } catch {
      exported.focus();
      exported.select();
      say('Press Ctrl+C to copy the selected code.');
    }
  });
  apply.addEventListener('click', () => {
    const code = imported.value.trim();
    if (!code) { say('Paste a settings code first.', true); imported.focus(); return; }
    if (code.length > 32768) { say('This code is too long.', true); return; }
    busy(true);
    say('Checking settings code…');
    try { window.sspSettingsCallback('import', code); }
    catch { busy(false); say('Import failed. Please close this dialog and try again.', true); }
  });
  undo.addEventListener('click', () => {
    busy(true);
    try { window.sspSettingsCallback('undo'); }
    catch { busy(false); say('Restore failed. Please try again.', true); }
  });
  document.getElementById('settings-code-close').addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => {
    window.sspSettingsCloseCallback?.();
    document.getElementById('canvas').focus();
  });
})();
