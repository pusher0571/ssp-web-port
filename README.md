# SSP Web Port

Inoffizieller Browser-Port von [Rhythia / Sound Space Plus](https://github.com/Rhythia/sound-space-plus), für PC mit Maus und Tastatur.

**Spielen:** https://pusher0571.github.io/ssp-web-port/

## Lokale Imports

Keine mitgelieferten Songs, kein Online-Katalog und keine Gameplay-Replays.

1. Spiel starten → Content Manager (Plus-Symbol links).
2. Sound Space Plus Map → Dateien wählen → eigene `.sspm` importieren.
3. Map auswählen und starten. **Spielen / Fortsetzen** fängt die Maus ein.
4. **ESC** pausiert und gibt die Maus frei; ein Klick setzt die Map fort.

Alternativ: Text-Map mit MP3/OGG. Vulnus-ZIP und alte Map-Packs sind im Web nicht verfügbar.

Maps, Einstellungen und Highscores bleiben im lokalen Browserspeicher. Imports werden nicht zum Host hochgeladen. Updates behalten bereits importierte Maps; das Löschen der Websitedaten entfernt sie.

## Browser und Audio

Godot 3.6.2, WebGL, Threads und AudioWorklet; Audio-Puffer 60 ms. Die Noten folgen der Audiozeit, ohne die Musik zur laufenden Synchronisierung neu zu starten. Der persönliche Audio-Offset ist im Spiel einstellbar.

Ein Service Worker im Spielverzeichnis ergänzt COOP/COEP-Header für Threads auf GitHub Pages. Beim ersten Aufruf lädt die Seite einmal neu. Er speichert keine Dateien zwischen. Benötigt werden HTTPS, Service Worker und Cross-Origin-Isolation. Falls der eingebettete Browser diese Funktionen verhindert, den Link in einem aktuellen Chrome, Edge oder Firefox öffnen.

## Lokal bauen und veröffentlichen

Benötigt: Python 3, [Godot 3.6.2](https://github.com/godotengine/godot-builds/releases/tag/3.6.2-stable) und dessen offizielle Web-Templates.

- `webassembly_threads_debug.zip` und `webassembly_threads_release.zip` nach `.tools/` kopieren.
- `python tools/build_web.py --godot /pfad/zu/godot`
- `python -m http.server 8765 --directory dist`
- `http://localhost:8765` öffnen.

`.github/workflows/web.yml` baut bei einem Push auf `main` und veröffentlicht auf GitHub Pages. Kein privater PC oder Cloudflare-Worker wird zum Hosten benötigt.

## Herkunft und Rechte

MIT-lizenzierter Spielcode aus dem [Originalprojekt](https://github.com/Rhythia/sound-space-plus). Basils ursprünglicher Copyright-Hinweis bleibt in [LICENSE.txt](LICENSE.txt). Weitere Hinweise stehen im Quellcode und den Schriftordnern (Lato, Noto Sans JP, Roboto). Die WAV-Effekte dieses Ports wurden mathematisch erzeugt; ursprüngliche Musik wird nicht mitgeliefert.

Kein offizielles Rhythia-Angebot. Die Code-Lizenz ist keine pauschale Erlaubnis für Musik, Coverbilder oder Marken Dritter. Importiere nur Dateien, die du verwenden darfst. Die übrigen Assets und das Angebot wurden nicht vollständig rechtlich geprüft.
