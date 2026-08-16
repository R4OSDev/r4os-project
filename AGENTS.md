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
  Diagnose, Library, Treiber oder Protokoll. In den Kernel kommt nur, was dort
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
  Drivers oder Protocols ein eigenes oeffentliches Repository in der
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

## Roadmap
- `Roadmap.txt` im Workspace-Root ist der lokale, nicht versionierte
  Arbeitsstand. Aufbau, Unterversionen und der Auftrag `Roadmap aufraeumen`
  stehen in `Agents/Roadmap.txt`.

## Shell und Befehlsausfuehrung
- Fuer PowerShell-, Batch- und Quotingregeln vor nichttrivialen Shellaufrufen
  `Agents/Shell.txt` lesen. Erfolg wird am Exitcode gemessen.

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
- Die API-Uebersicht liegt unter
  `Repositories/Contract/Generated/Inventory/API.json`.
- Serverarbeiten sind ausschliesslich in `Server/Agents/Server.txt`
  dokumentiert. (Nicht öffentlich)

# Module und API/ABI
- Anwendungen, Dienste und Diagnosen (`.R4X`), Treiber (`.R4D`),
  Runtime-Libraries und SDK-Plattform-Bridges (`.R4L`) sowie Protokolle
  (`.R4P`) verwenden den gemeinsamen R4M0-Container.
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
