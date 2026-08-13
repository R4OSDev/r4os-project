# Einleitung

R4OS ist ein in Zig entwickeltes Betriebssystem fuer x86_64. Es startet ueber
Limine im Long Mode und verbindet eine an DOS und Windows 98 angelehnte
Systemstruktur mit eigenstaendigen Anwendungen, Diensten, Libraries, Treibern
und Protokollen. R4OS ist ein Single-User-System, gilt vollstaendig als
vertrauenswuerdig und besitzt bewusst kein Benutzer-, Rechte- oder
Sandboxmodell.

# GitHub
- Das private GitHub-Projektverzeichnis `D:\R4OS\` wird als
  `R4OSDev/r4os-project` auf dem Branch `main` gesichert.
- Fuer Push und Pull ausschliesslich `D:\R4OS\Tools\Github.bat` verwenden.
  Ohne Argumente fragt es interaktiv erst nach `Push` oder `Pull` und danach
  nach dem Projekt. Weitere Ziele werden spaeter ergaenzt.
- Nach einem frischen Clone zuerst `D:\R4OS\Tools\Setup.bat` ausfuehren.
  Es erzeugt die ignorierten Workspace-Ordner `Artifacts`, `DevKit` und
  `Repositories` sowie bei Bedarf die lokale GitHub-Credentials-Vorlage.
- Direkte Aufrufe:
  - `Github.bat -push -project ["Commit-Beschreibung"]`
  - `Github.bat -pull -project`
- Ein Push staged nach `D:\R4OS\.gitignore`, erstellt bei Aenderungen einen
  Commit und pusht `main`. Ein Pull verwendet ausschliesslich
  `git pull --ff-only`.
- Zugangsdaten liegen nur lokal unter
  `D:\R4OS\Tools\Credentials\Github.bat` und duerfen nie gelesen,
  angezeigt oder gepusht werden.
