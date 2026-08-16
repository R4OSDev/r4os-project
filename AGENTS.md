# Einleitung
R4OS ist ein in Zig entwickeltes Betriebssystem fuer x86_64. Es startet ueber
Limine im Long Mode und verbindet eine an DOS und Windows 98 angelehnte
Systemstruktur mit eigenstaendigen Anwendungen, Diensten, Libraries, Treibern
und Protokollen. R4OS ist ein Single-User-System, gilt vollstaendig als
vertrauenswuerdig und besitzt bewusst kein Benutzer-, Rechte- oder
Sandboxmodell.

# Lizenz
- Originales R4OS-Material steht in allen kanonischen Repositories unter der
  Apache License 2.0.
- Jedes Repository besitzt im Root die bytegleiche `LICENSE` und ein kurzes
  `NOTICE` mit `Copyright 2026 R4` sowie der Nennung von R4 als
  urspruenglichem Autor.
- Material Dritter wird dadurch nicht umlizenziert. Dessen Lizenz- und
  Herkunftshinweise bleiben erhalten und werden repositorybezogen in
  `THIRD_PARTY_NOTICES.md` dokumentiert.
- Distributionsimages enthalten unter `R4OS/LICENSES` Apache-Lizenz, NOTICE,
  Gesamtuebersicht und die vollstaendigen erforderlichen Fremdlizenztexte.
  `Repositories/Distribution/Build.bat image <Profil>` stageiert dieselbe
  Rechtsdokumentation neben `disk.img` unter `Legal`.
- Besondere Lizenzgrenze: Die mechanisch aus dem GPL-2.0-only-Realtek-
  Vendortreiber erzeugten Firmwaretabellen in `Drivers/RTL8168` sowie
  Binaerartefakte, die sie enthalten, werden als GPL-2.0-only dokumentiert.
- Repository-Einstiege und sonstige `README*`-Dateien sind
  Englisch. Ausfuehrliche uebernommene deutsche Root-Dokumentation bleibt als
  `DOCUMENTATION.de.txt` erhalten.

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
- Das private GitHub-Projektverzeichnis `D:\R4OS` wird als
  `R4OSDev/r4os-project` auf dem Branch `main` gesichert.
- Das private DevKit-Repository liegt unter `D:\R4OS\DevKit` und wird
  als `R4OSDev/r4os-devkit` auf dem Branch `main` verwaltet. Installierte
  Inhalte werden durch dessen eigene `.gitignore` ausgeschlossen.
- `D:\R4OS\DevKit\Setup\Setup_Windows.bat` installiert Zig, Limine und QEMU,
  klont beziehungsweise aktualisiert installierte Contract-, SDK- und
  Distribution-Kopien unter `DevKit\SDK` beziehungsweise
  `DevKit\HostTools\Source` und baut deren elf Hostprogramme nach
  `DevKit\HostTools\bin`. Updates sind nur als Fast-Forward auf `main`
  erlaubt; lokale Aenderungen in den Installationskopien fuehren zum Abbruch.
  Diese Kopien sind keine fachlichen Quellwahrheiten und werden nicht editiert.
- Der kanonische API-/ABI-Vertrag liegt unter
  `D:\R4OS\Repositories\Contract` und wird als `R4OSDev/r4os-contract` auf
  dem Branch `main` verwaltet.
- Das hostneutrale SDK liegt unter `D:\R4OS\Repositories\SDK` und wird als
  `R4OSDev/r4os-sdk` auf dem Branch `main` verwaltet.
- Die SDK-Pfade stehen in `D:\R4OS\Repositories\SDK\Settings.R4S`.
  Relative Komponentenpfade beginnen am dort gemappten Repositories-Ordner;
  absolute Pfade sind ebenfalls erlaubt. SDK-Builds werden unter Windows mit
  `Build.bat`, unter Linux/macOS mit `Build.sh` gestartet, damit die Mappings
  bereits vor der Zig-Paketaufloesung gelten.
- Die offiziellen unabhaengigen Runtime-Libraries liegen unter
  `D:\R4OS\Repositories\Libraries` und werden als
  `R4OSDev/r4os-libraries` auf dem Branch `main` verwaltet.
- Der Kernel liegt unter `D:\R4OS\Repositories\Kernel` und wird als
  `R4OSDev/r4os-kernel` auf dem Branch `main` verwaltet.
- Die Distribution liegt unter `D:\R4OS\Repositories\Distribution` und wird
  als `R4OSDev/r4os-distribution` auf dem Branch `main` verwaltet.
- Eigenstaendige Komponenten liegen nach ihrer fachlichen Rolle unter
  `D:\R4OS\Repositories\Apps`, `Services`, `Diagnostics`, `Drivers`
  oder `Protocols`.
  Die ersten Piloten sind `Apps\Clock` als `R4OSDev/r4os-app-clock`,
  `Drivers\MIDI` als `R4OSDev/r4os-driver-midi` und `Protocols\JSON` als
  `R4OSDev/r4os-protocol-json`. Der erste Diagnosepilot ist
  `Diagnostics\FsDiag` als `R4OSDev/r4os-diagnostic-fsdiag`.
  Diese Komponentenrepositories bleiben vorerst privat. Eine spaetere
  Veroeffentlichung ist eine separate Entscheidung.
  Jedes Modul besitzt eigene Settings und Buildstarter; relative Settings
  beginnen am jeweiligen Modulrepository und duerfen durch absolute Pfade
  ersetzt werden. Fertige Pilotartefakte landen standardmaessig unter
  `D:\R4OS\Artifacts\Modules\<Name>`.
- Jeder Modul-Buildstarter bindet die in seiner `Settings.R4S` gemappten
  aktuellen lokalen Checkouts von SDK, Contract und den tatsaechlich
  benoetigten Librarybindings mit Zig `--fork` ein. Eine inkompatible lokale
  Aenderung darf den Verbraucherbuild sichtbar brechen und wird dann im
  Verbraucher angepasst.
- URL und Commit in `build.zig.zon` sind der zuletzt gepruefte
  Standalone-Referenzstand, kein verpflichtender Workspace-Lock. Sie werden
  nur zum Fallback, wenn jemand den verbindlichen Buildstarter umgeht und
  direkt `zig build` ohne lokale Forks aufruft.
- `Sdk.addR4MFWithOptions` ersetzt die im Manifest deklarierten
  ZIG_MODULE-Quellpfade in Manifestreihenfolge durch explizite Paketpfade.
  Namen und Importvertrag bleiben allein in `module.R4MF`.
- Distributionspfade stehen in
  `D:\R4OS\Repositories\Distribution\Settings.R4S`. `Build.bat test` baut
  die sieben distributionseigenen Hosttools und prueft die deterministischen
  Slim-, Full- und Test-Imageplaene. `Build.bat plan`, `image`, `verify`,
  `qemu` und `headless Test` arbeiten je Profil ausschliesslich mit expliziten fertigen
  Artefaktplaenen unter `Artifacts\Distribution\Inputs`; sie bauen niemals
  Kernel, Libraries oder Module. Private Injection-Dateien liegen nur im
  ignorierten `Artifacts\Distribution\PrivateInjection`-Overlay.
- Die QEMU-Binaries gehoeren ausschliesslich in
  `D:\R4OS\DevKit\Emulation\QEMU`. `Repositories\Distribution\QEMU` enthaelt
  nur R4OS-spezifische Konfiguration; der Headless-Lauf schreibt seine Logs
  nach `Artifacts\Distribution\Logs` und verlangt Bootmarker sowie Poweroff.
- Kernel-Pfade stehen in `D:\R4OS\Repositories\Kernel\Settings.R4S`.
  `Build.bat` erzeugt `zig-out\bin\r4os.elf`; `Build.bat test` baut den
  Kernel und fuehrt die kernel-eigenen Host- und Negativtests aus. Der Build
  konsumiert nur den gemappten Contract und bleibt fest auf ReleaseSafe ohne
  SIMD. `Build.sh` ist der hostneutrale Starter; Linux-/macOS-Laufzeittests
  sind fuer den 0.64-Umbau kein Gate. `VERSION.R4S` nur erhoehen, wenn sich
  das Kernelartefakt tatsaechlich aendert.
- Library-Pfade stehen in `D:\R4OS\Repositories\Libraries\Settings.R4S`.
  `Build.bat test` prueft alle Libraries; mit `Build.bat R4STD test`,
  `Build.bat R4IMG test` oder `Build.bat R4FONT test` wird genau eine Einheit
  gebaut und getestet. Relative und absolute SDK-/Contract-Pfade sind
  erlaubt. Linux-/macOS-Laufzeittests sind fuer den 0.64-Umbau kein Gate.

# Workspace-Build
- Der verbindliche Mehrrepo-Einstieg unter Windows ist
  `D:\R4OS\Tools\Build.bat`. Ohne Argumente zeigt er ein interaktives Menue.
- `Build.bat -central`, `-kernel`, `-modules`, `-module Rolle\Name`,
  `-plan Profil`, `-image Profil`, `-verify Profil`, `-qemu Profil`,
  `-all Profil`, `-slim`, `-gui`, `-test`, `-testimage`, `-testimageonly`,
  `-testonly` und `-headless` sind die direkten Aufrufe. Profile sind `Slim`,
  `Full` und `Test`.
- Der Workspace-Build entdeckt Komponenten dynamisch in `Apps`, `Services`,
  `Diagnostics`, `Drivers` und `Protocols` und ruft immer deren eigenes
  `Build.bat` auf. Versionierte sowie nicht ignorierte modulnahe
  Zusatzmanifeste wie LoaderDiag-Fixtures werden aus ihrem Eigentuerrepo
  ebenfalls in den Profilplan aufgenommen; ignorierte Paketkopien nicht. Er
  aktualisiert keine Git-Repositories automatisch und zeigt die verwendeten
  lokalen zentralen Commitstaende vor dem Lauf an.
- Der Root baut kein Image selbst. Er erzeugt aus `module.R4MF` und den
  fertigen Artefakten nur die expliziten Plaene unter
  `Artifacts\Distribution\Inputs` sowie das dazu passende `MODULES.JSON` und
  delegiert `image`, `verify`, `qemu` und `headless` ausschliesslich an
  `Repositories\Distribution\Build.bat`.
- `Build.bat -gui` baut den kompletten Full-Workspace, laesst Distribution
  das Full-Image erzeugen und startet danach QEMU sichtbar. `Build.bat -qemu`
  startet dagegen nur ein bereits vorhandenes Image.
- Fuer Push und Pull ausschliesslich `D:\R4OS\Tools\Github.bat` verwenden.
  Ohne Argumente fragt es interaktiv erst nach `Push` oder `Pull` und danach
  nach `Project`, `DevKit`, `Contract`, `SDK`, `Libraries`, `Kernel`,
  `Distribution`, einer Anwendung, einem Dienst, Diagnoseprogramm, Treiber
  oder Protokoll.
- Nach einem frischen Clone zuerst `D:\R4OS\Tools\Setup.bat` ausfuehren.
  Es erzeugt die ignorierten Workspace-Ordner `Artifacts`, `DevKit` und
  `Repositories`, die Rollenordner `Apps`, `Services`, `Diagnostics`,
  `Drivers` und `Protocols`, die lokalen Modul-/Distribution-Artefaktwurzeln
  und bei Bedarf die lokale GitHub-Credentials-Vorlage.
  Anschliessend das DevKit mit `Github.bat -pull -devkit` beziehen und darin
  `Setup\Setup_Windows.bat` ausfuehren.
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
  - `Github.bat -push -kernel ["Commit-Beschreibung"]`
  - `Github.bat -pull -kernel`
  - `Github.bat -push -distribution ["Commit-Beschreibung"]`
  - `Github.bat -pull -distribution`
  - `Github.bat -push -app Clock ["Commit-Beschreibung"]`
  - `Github.bat -pull -app Clock`
  - `Github.bat -push -service SSHD ["Commit-Beschreibung"]`
  - `Github.bat -pull -service SSHD`
  - `Github.bat -push -diagnostic FsDiag ["Commit-Beschreibung"]`
  - `Github.bat -pull -diagnostic FsDiag`
  - `Github.bat -push -driver MIDI ["Commit-Beschreibung"]`
  - `Github.bat -pull -driver MIDI`
  - `Github.bat -push -protocol JSON ["Commit-Beschreibung"]`
  - `Github.bat -pull -protocol JSON`
- Ein Push staged nach der `.gitignore` des gewaehlten Repositorys, erstellt
  bei Aenderungen einen Commit und pusht `main`. Ein Pull verwendet
  ausschliesslich `git pull --ff-only`. Beim ersten Push eines neuen Ziels
  werden das lokale Repository und bei ausreichender Token-Berechtigung auch
  das GitHub-Repository angelegt. Verweigert GitHub die Organisationserstellung,
  wird das leere Repository einmalig manuell angelegt und derselbe Push erneut
  gestartet.
- Zugangsdaten liegen nur lokal unter
  `D:\R4OS\Tools\Credentials\Github.bat` und duerfen nie gelesen,
  angezeigt oder gepusht werden.
