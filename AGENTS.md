# Einleitung
R4OS ist ein in Zig entwickeltes Betriebssystem fuer x86_64. Es startet ueber
Limine im Long Mode und verbindet eine an DOS und Windows 98 angelehnte
Systemstruktur mit eigenstaendigen Anwendungen, Diensten, Libraries, Treibern
und Protokollen. R4OS ist ein Single-User-System, gilt vollstaendig als
vertrauenswuerdig und besitzt bewusst kein Benutzer-, Rechte- oder
Sandboxmodell.

# Verbindliche Arbeitsweise
- Der lokale Workspace ist `D:\R4OS`. Das Root-Repository koordiniert die
  Arbeit; jede Quellkomponente wird im Repository ihres fachlichen Besitzers
  bearbeitet.
- Neue Funktionen zuerst einer externen Rolle zuordnen: App, Service,
  Diagnose, Library, Treiber, Protokoll oder Subsystem. In den Kernel kommt nur, was dort
  technisch zwingend hingehoert.
- Lokal arbeiten. Es duerfen keine Subagents gestartet oder verwendet werden.
- Aenderungen vor dem Abschluss in einem ihrem Risiko angemessenen Umfang
  bauen und testen.
- Inventare sind Teil der jeweiligen Aenderung: Neue, verschobene oder
  entfernte kanonische Module in `Docs/Inventory/AllModules.json` nachziehen.
  Neue, geaenderte, verschobene oder entfernte Tests in
  `Docs/Inventory/Tests.json` nachziehen. Der Workspace-Build gleicht den
  Dateibestand von `Docs/Inventory/Docs.json` automatisch ab; Beschreibung,
  letzter Pruefstand in `Status` und optionale `Notes` werden bei der
  inhaltlichen Dokumentarbeit manuell gepflegt.
- Fuer jedes neue kanonische Projekt unter Apps, Services, Diagnostics,
  Drivers, Protocols oder Subsystems ein eigenes oeffentliches Repository in der
  GitHub-Organisation `R4OSDev` anlegen. Benennung und Zielzuordnung stehen in
  `Agents/Github.txt`.
- Ist eine Unterversion abgeschlossen, `RELEASE_VERSION` in
  `Repositories/Distribution/Injection/R4OS/CONFIG/VERSION.R4S` anpassen.
  `Repositories/Kernel/VERSION.R4S` nur bei einer Aenderung des
  Kernelartefakts erhoehen; die `VERSION` in `module.R4MF` nur bei einer
  Aenderung des jeweiligen Modulartefakts.
- 1 MB entspricht nach R4OS-Sprechweise 1024 KB.
- Produktiver Code und aktuelle Dokumentation sind current-only. Historische
  Begriffe und Pfade gehoeren nur in Changelogs und ausdrueckliche
  Abschlussberichte.
- Temporäre Hilfs-Scripts und diverse Dateien sollen wenn möglich nach Temp/.
  Das Temp/ Verzeichnis wird unregelmäßig geleert.
- In `AGENTS.md` duerfen ohne Rueckfrage nur die Abschnitte
  `Shell und Befehlsausfuehrung` und `Wichtige Konventionen` samt ihrer
  Unterbereiche geaendert werden. Fuer andere Abschnitte vorher den User um
  Erlaubnis fragen.

## GitHub
- Push und Pull fuer Project, DevKit, Docs und Quell-Repositories
  ausschliesslich mit `Tools/Github.bat` ausfuehren. Der private Package-
  Server ist die einzige Ausnahme und wird mit `Server/Push.bat` sowie
  `Server/Pull.bat` verwaltet. Zielzuordnung, Aufrufe, Credentials und
  Pruefablauf stehen in `Agents/Github.txt`.
- Nach Abschluss einer Unterversion oder sonstigen Arbeit den verbindlichen
  Sammel-Push `Tools/Github.bat -push -changed "Commit-Beschreibung"`
  verwenden. Er erkennt und veroeffentlicht alle geaenderten verwalteten
  Repositories; gezielte Einzel-Pushes bleiben Reparatur- und Sonderfaellen
  vorbehalten. Pulls erfolgen weiterhin gezielt pro Repository.
- Neu erstellte R4OS-Quellrepositories sind oeffentlich. Der Package-Server
  und kuenftige Server-Repositories bilden die private Ausnahme.

## Build und Tests
- Mehrrepository-Builds ueber `Tools/Build.bat` starten; ohne Argumente zeigt
  der Starter sein interaktives Menue. Einzelbuilds ueber das `Build.bat` des
  zustaendigen Repositories ausfuehren.
- Buildmodi, Profile, Reihenfolge, Artefakte, QEMU, Bereinigung und
  Fehlersuche stehen in `Agents/Build.txt`. Testschichten und Inventarpflege
  stehen in `Agents/Test.txt` und `Agents/TestCategories.txt`.

## Shell und Befehlsausfuehrung
- Fuer PowerShell-, Batch- und Quotingregeln vor nichttrivialen Shellaufrufen
  `Agents/Shell.txt` lesen. Erfolg wird am Exitcode gemessen.
  
# Arbeiten mit der Roadmap

Wir strukturieren unsere Arbeit mit Hilfe einer Roadmap.
Die API liefert und empfängt überwiegend JSON. Der Markdown-Export liefert `text/markdown`.
„Ergänzen“ fügt einem Wert einen Zeilenumbruch und danach den gesendeten Text hinzu.

`{subversion_id}` ist innerhalb der aktuellen Hauptversion lokal und beginnt bei `1`.
`{task_id}` ist innerhalb seiner Unterversion lokal und beginnt bei `1`.

Neue Unterversionen werden ohne `sortierung` automatisch am Ende eingeordnet. Eine explizite `sortierung` ist weiterhin möglich.

## Roadmap lesen und bearbeiten

- Gesamte aktuelle Version erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current`
- Gesamte aktuelle Version überschreiben (Gefährlich): `PUT http://10.0.0.2:4011/roadmaps/1/current`

- Leitbild der aktuellen Version erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/vision`
- Leitbild der aktuellen Version überschreiben: `PUT http://10.0.0.2:4011/roadmaps/1/current/vision`
-- `{"vision":"Neues Leitbild"}`

- Allgemeine Notizen der aktuellen Version erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/notes`
- Allgemeine Notizen der aktuellen Version überschreiben (Gefährlich): `PUT http://10.0.0.2:4011/roadmaps/1/current/notes`
-- `{"notes":"Neue allgemeine Versionsnotizen"}`
- Allgemeine Notizen der aktuellen Version ergänzen: `POST http://10.0.0.2:4011/roadmaps/1/current/notes/append`
-- `{"notes":"Zusätzliche Notiz"}`

- Nur alle Unterversionen erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversions`

- Status der aktuellen Version ändern: `PATCH http://10.0.0.2:4011/roadmaps/1/current/status`
-- `{"status":"Abgeschlossen"}`
-- Mögliche Werte: `Offen`, `Abgeschlossen`, `Verworfen`

## Unterversionen lesen und bearbeiten

- Unterversion erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}`
- Unterversion vollständig überschreiben (Gefährlich): `PUT http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}`
-- `{"versionsnummer":"0.66.5","titel":"Neuer Schritt","status":"Offen","beschreibung":"","notizen":"","sortierung":5,"tasks":[{"beschreibung":"Aufgabe A","status":"Offen","notizen":"","sortierung":0}],"abnahmen":[{"beschreibung":"Abnahme A","status":"Offen","notizen":"","sortierung":0}]}`

- Einzelne Felder einer Unterversion ändern: `PATCH http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}`
-- Beispiel für eine neue Reihenfolge: `{"sortierung":5}`

- Neue Unterversion inklusive Aufgaben und Abnahmen erstellen: `POST http://10.0.0.2:4011/roadmaps/1/current/subversions`
-- `{"versionsnummer":"0.66.5","titel":"Neuer Schritt","beschreibung":"","notizen":"","tasks":[{"beschreibung":"Aufgabe A","notizen":""}],"abnahmen":[{"beschreibung":"Abnahme A","notizen":""}]}`
-- Neue Elemente erhalten standardmäßig den Status `Offen`.
-- Ohne `sortierung` wird die Unterversion automatisch am Ende einsortiert.
-- `sortierung` kann bei Bedarf explizit übermittelt werden.

- Status einer Unterversion ändern: `PATCH http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/status`
-- `{"status":"Abgeschlossen"}`
-- Mögliche Werte: `Offen`, `Abgeschlossen`, `Verworfen`

- Notizen einer Unterversion erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/notes`
- Notizen einer Unterversion überschreiben (Gefährlich): `PUT http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/notes`
-- `{"notes":"Neue Notizen"}`
- Notizen einer Unterversion ergänzen: `POST http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/notes/append`
-- `{"notes":"Zusätzliche Notiz"}`

## Aufgaben

- Aufgabe erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/task/{task_id}`
- Aufgabe überschreiben: `PUT http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/task/{task_id}`
-- `{"beschreibung":"Aufgabe","status":"Offen","notizen":"","sortierung":0}`

- Neue Aufgabe erstellen: `POST http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/tasks`
-- `{"beschreibung":"Neue Aufgabe","notizen":""}`

- Status einer Aufgabe ändern: `PATCH http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/task/{task_id}/status`
-- `{"status":"Erledigt"}`
-- Mögliche Werte: `Offen`, `Erledigt`, `Verworfen`

- Notizen einer Aufgabe erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/task/{task_id}/notes`
- Notizen einer Aufgabe überschreiben: `PUT http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/task/{task_id}/notes`
-- `{"notes":"Neue Notizen"}`
- Notizen einer Aufgabe ergänzen: `POST http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/task/{task_id}/notes/append`
-- `{"notes":"Zusätzliche Notiz"}`

## Abnahmen

- Abnahme erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptance/{acceptance_id}`
- Abnahme überschreiben: `PUT http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptance/{acceptance_id}`
-- `{"beschreibung":"Abnahme","status":"Offen","notizen":"","sortierung":0}`

- Neue Abnahme erstellen: `POST http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptances`
-- `{"beschreibung":"Neue Abnahme","notizen":""}`

- Status einer Abnahme ändern: `PATCH http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptance/{acceptance_id}/status`
-- `{"status":"Erledigt"}`
-- Mögliche Werte: `Offen`, `Erledigt`, `Verworfen`

- Notizen einer Abnahme erhalten: `GET http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptance/{acceptance_id}/notes`
- Notizen einer Abnahme überschreiben: `PUT http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptance/{acceptance_id}/notes`
-- `{"notes":"Neue Notizen"}`
- Notizen einer Abnahme ergänzen: `POST http://10.0.0.2:4011/roadmaps/1/current/subversion/{subversion_id}/acceptance/{acceptance_id}/notes/append`
-- `{"notes":"Zusätzliche Notiz"}`

## Roadmap aufräumen

Nur wenn der User das Aufräumen der Roadmap explizit verlangt:

- Schau dir die Roadmap nochmal an und aktualisiere bei Bedarf unsere `Docs/`.
- Hol dir die Roadmap komplett im Markdown-Format und lege sie unter `Docs/Changelogs/` ab, beispielsweise als `V0.20.X.txt`.
-- `GET http://10.0.0.2:4011/roadmaps/1/current/markdown`
- Setze den Status der aktuellen Version auf `Abgeschlossen`.
- Erstelle eine neue leere Version der Roadmap: `POST http://10.0.0.2:4011/roadmaps/1/versions/next`
-- Kein JSON-Body nötig. Die Version erhält automatisch die nächste Versionsnummer, den Titel `Neu` und den Status `Offen`.

# Workspace, Dokumentation und Inventare
- Besitzgrenzen, Repositoryrollen, DevKit, Distribution und Artefakte stehen
  in `Agents/ProjektStruktur.txt`.
- Projektweite Dokumentation liegt im eigenen Repository `Docs/` und wird in
  `Docs/Inventory/Docs.json` gepflegt. `Agents/`, `Docs/Inventory/` und
  Changelogs werden dort nicht aufgenommen.
- `Docs/Inventory/AllModules.json`, `Docs/Inventory/Tests.json` und
  `Docs/Inventory/Browser.json` werden manuell gepflegt. In `Docs.json` wird
  der Dateibestand automatisch und werden die inhaltlichen Felder manuell
  gepflegt. Das profilspezifische technische Inventar
  `Artifacts/Distribution/Generated/MODULES.JSON` entsteht beim Imageplan.
  Seine Schema-4-Subsystemeintraege sind die einzige persistente Quelle des
  installierten Userland-Subsystemkatalogs; es gibt keine zweite Hostliste.
- Die API-Uebersicht liegt unter
  `Repositories/Contract/Generated/Inventory/API.json`.
- Serverarbeiten sind ausschliesslich in `Server/Agents/Server.txt`
  dokumentiert. (Nicht öffentlich)

# Module und API/ABI
- Anwendungen, Dienste und Diagnosen (`.R4X`), Runtime-Libraries (`.R4L`),
  Treiber (`.R4D`) und Protokolle (`.R4P`) verwenden den gemeinsamen
  R4M0-Dateicontainer.
- R4SYS, R4DESK, R4DRAW, R4NET, R4AUDIO und R4DEV sind eingebaute Platform
  APIs des Kernels. Sie behalten ihre `Query:1`-Importnamen, besitzen aber
  kein eigenes `.R4L`-Dateimodul und keine getrennte Modulversion.
- Build-, Versions-, Ziel- und Abhaengigkeitswahrheit jedes Moduls ist dessen
  `module.R4MF`. Container und Modulprojekt stehen in
  `Agents/R4M0-Container.txt`.
- Der zentrale Plattformvertrag gehoert `Repositories/Contract/`; unabhaengige
  Runtime-R4Ls besitzen ihren Contract in ihrer Library-Einheit. Generierung,
  Kompatibilitaet und Fassadengrenzen stehen in `Agents/API-ABI.txt`.

# Wichtige Konventionen
- Vor Aenderungen an Kernel, Scheduler, Programmlebenszyklus, Systempfaden,
  Services oder Self-Hosting `Agents/Konventionen.txt` und die dort genannten
  Besitzervertraege lesen.
- Kernelstruktur: `Agents/KernelStruktur.txt`; Dateitypen:
  `Agents/DateiTypen.txt`; Remote-Updates: `Agents/RemoteUpdate.txt`;
  Lizenzierung und Fremdmaterial: `Agents/Lizenz.txt`.
- `ASSOC.R4S` speichert fuer Subsystemhandler nur stabile Subsystem- und
  Gastformat-IDs. Hostpfad, Anzeigename, Formate und Probes kommen immer aus
  dem installierten `MODULES.JSON`. Gaststarts verwenden den
  `R4SUBSYS1`-Vertrag und erzeugen pro geoeffneter Datei eine neue R4X-Instanz.
- Subsystem-Fensterhosts verwenden die einkompilierte SDK-Schicht
  `r4os.subsystem_host`: Gastaufloesung und Fensterviewport bleiben getrennt,
  Rasterbloecke sind hoechstens 128x128 Pixel gross, unveraenderte Bilder
  erzeugen keinen Frame und Letterboxbereiche liefern keine Gastmausposition.
  Scheduling, Gastzeit und Audio gehoeren nicht in diesen Video-/Eingabehost.
- Kooperative Gastlaufzeiten verwenden `r4os.subsystem_runtime`: genau eine
  begrenzte Gast-Scheibe pro Hostzyklus, monotone pausenbereinigte Gastzeit,
  caller-eigene PCM-Puffer und Audio ausschliesslich ueber App-Audio/AUDSVC.
  Audioausfall setzt den Teilpfad auf `degraded`, darf Gastzeit und Video aber
  weder beschleunigen noch blockieren; Abschluss, Close und Fehler muessen
  denselben idempotenten Ressourcenabbau erreichen.
