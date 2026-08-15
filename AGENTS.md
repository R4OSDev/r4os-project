# Einleitung
R4OS ist ein in Zig entwickeltes Betriebssystem fuer x86_64. Es startet ueber
Limine im Long Mode und verbindet eine an DOS und Windows 98 angelehnte
Systemstruktur mit eigenstaendigen Anwendungen, Diensten, Libraries, Treibern
und Protokollen. R4OS ist ein Single-User-System, gilt vollstaendig als
vertrauenswuerdig und besitzt bewusst kein Benutzer-, Rechte- oder
Sandboxmodell.

# Umbau
Aktuell strukturieren wir alles um.
Das neue und aktuelle R4OS Projekt-Verzeichnis ist D:\R4OS\
Das alte ist: D:\AI\Projects\Claude Code\R4OS

- Der eingefrorene fachliche Referenzstand ist Altprojekt-Commit `259cbfac`;
  der archivierte Abschluss-Head ist `2c0ca047`.
- Die verbindliche Repository- und Dateizuordnung steht unter
  `Agents/SourceMap06410.txt`.
- Eine Komponente wird erst nach eigenstaendigem Build und ihren Tests im
  neuen Repository kanonisch. Bis dahin bleibt ihr Teilbaum aus `259cbfac`
  die einzige fachliche Wahrheit.

# GitHub
- Das private GitHub-Projektverzeichnis `D:\R4OS\` wird als
  `R4OSDev/r4os-project` auf dem Branch `main` gesichert.
- Das oeffentliche DevKit-Repository liegt unter `D:\R4OS\DevKit\` und wird
  als `R4OSDev/r4os-devkit` auf dem Branch `main` verwaltet. Installierte
  Inhalte werden durch dessen eigene `.gitignore` ausgeschlossen.
- Der kanonische API-/ABI-Vertrag liegt unter
  `D:\R4OS\Repositories\Contract\` und wird als `R4OSDev/r4os-contract` auf
  dem Branch `main` verwaltet.
- Das hostneutrale SDK liegt unter `D:\R4OS\Repositories\SDK\` und wird als
  `R4OSDev/r4os-sdk` auf dem Branch `main` verwaltet.
- Die SDK-Pfade stehen in `D:\R4OS\Repositories\SDK\Settings.R4S`.
  Relative Komponentenpfade beginnen am dort gemappten Repositories-Ordner;
  absolute Pfade sind ebenfalls erlaubt. SDK-Builds werden unter Windows mit
  `Build.bat`, unter Linux/macOS mit `Build.sh` gestartet, damit die Mappings
  bereits vor der Zig-Paketaufloesung gelten.
- Die offiziellen unabhaengigen Runtime-Libraries liegen unter
  `D:\R4OS\Repositories\Libraries\` und werden als
  `R4OSDev/r4os-libraries` auf dem Branch `main` verwaltet.
- Library-Pfade stehen in `D:\R4OS\Repositories\Libraries\Settings.R4S`.
  `Build.bat test` prueft alle Libraries; mit `Build.bat R4STD test`,
  `Build.bat R4IMG test` oder `Build.bat R4FONT test` wird genau eine Einheit
  gebaut und getestet. Relative und absolute SDK-/Contract-Pfade sind
  erlaubt. Linux-/macOS-Laufzeittests sind fuer den 0.64-Umbau kein Gate.
- Fuer Push und Pull ausschliesslich `D:\R4OS\Tools\Github.bat` verwenden.
  Ohne Argumente fragt es interaktiv erst nach `Push` oder `Pull` und danach
  nach `Project`, `DevKit`, `Contract`, `SDK` oder `Libraries`.
- Nach einem frischen Clone zuerst `D:\R4OS\Tools\Setup.bat` ausfuehren.
  Es erzeugt die ignorierten Workspace-Ordner `Artifacts`, `DevKit` und
  `Repositories` sowie bei Bedarf die lokale GitHub-Credentials-Vorlage.
- Direkte Aufrufe:
  - `Github.bat -push -project ["Commit-Beschreibung"]`
  - `Github.bat -pull -project`
  - `Github.bat -push -devkit ["Commit-Beschreibung"]`
  - `Github.bat -pull -devkit`
  - `Github.bat -push -contract ["Commit-Beschreibung"]`
  - `Github.bat -pull -contract`
  - `Github.bat -push -sdk ["Commit-Beschreibung"]`
  - `Github.bat -pull -sdk`
  - `Github.bat -push -libraries ["Commit-Beschreibung"]`
  - `Github.bat -pull -libraries`
- Ein Push staged nach der `.gitignore` des gewaehlten Repositorys, erstellt
  bei Aenderungen einen Commit und pusht `main`. Ein Pull verwendet
  ausschliesslich `git pull --ff-only`. Beim ersten Push eines neuen Ziels
  werden das lokale Repository und bei Bedarf das GitHub-Repository angelegt.
- Zugangsdaten liegen nur lokal unter
  `D:\R4OS\Tools\Credentials\Github.bat` und duerfen nie gelesen,
  angezeigt oder gepusht werden.
