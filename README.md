# R4OS Project

Privater Workspace fuer die Entwicklung und Aufteilung von R4OS.

    DevKit\        Installierte SDK- und Hostwerkzeuge
    Repositories\  Eigenstaendige R4OS-Quell-Repositories
      Modules\     Je ein Repository pro Anwendung, Treiber oder Protokoll
    Artifacts\     Lokale Build- und Testergebnisse
    Tools\         Workspace-Setup und GitHub-Verwaltung

Nach einem frischen Clone zuerst `Tools\Setup.bat` ausfuehren und danach die
lokale Credentials-Vorlage ausfuellen. Anschliessend mit
`Tools\Github.bat -pull -devkit` das DevKit beziehen und dort
`Setup\Setup_Windows.bat` starten. Push und Pull erfolgen ausschliesslich ueber
`Tools\Github.bat`.

Komponentenquellen, installierte Werkzeuge, Buildartefakte und Zugangsdaten
werden nicht in diesem Repository gespeichert.
