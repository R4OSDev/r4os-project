# R4OS Project

Privater Workspace fuer die Entwicklung und Aufteilung von R4OS.

    DevKit\        Installierte SDK- und Hostwerkzeuge
    Repositories\  Eigenstaendige R4OS-Quell-Repositories
      Apps\         Anwendungen
      Services\     Dienste
      Diagnostics\  Diagnoseprogramme
      Drivers\      Treiber
      Protocols\    Protokolle
    Artifacts\     Lokale Build- und Testergebnisse
    Tools\         Workspace-Setup und GitHub-Verwaltung

Nach einem frischen Clone zuerst `Tools\Setup.bat` ausfuehren und danach die
lokale Credentials-Vorlage ausfuellen. Anschliessend mit
`Tools\Github.bat -pull -devkit` das DevKit beziehen und dort
`Setup\Setup_Windows.bat` starten. Push und Pull erfolgen ausschliesslich ueber
`Tools\Github.bat`.

Der gemeinsame Windows-Build startet mit `Tools\Build.bat`; ohne Argumente
erscheint das Menue. `Tools\Build.bat -all` baut den gesamten Workspace und
das Full-Image, `-gui` startet danach QEMU sichtbar und `-qemu` startet nur ein
bereits vorhandenes Image. Image-Erzeugung und QEMU bleiben Eigentum von
`Repositories\Distribution\Build.bat`.

Komponentenquellen, installierte Werkzeuge, Buildartefakte und Zugangsdaten
werden nicht in diesem Repository gespeichert.
