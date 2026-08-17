@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "R4OS_PROJECT_ROOT=%%~fI"
set "R4OS_CREDENTIAL_DIR=%~dp0Credentials"
set "R4OS_CREDENTIAL_FILE=%~dp0Credentials\Github.bat"

for %%F in (QuickNotes.txt Roadmap.txt) do (
    if not exist "%R4OS_PROJECT_ROOT%\%%F" (
        type nul >"%R4OS_PROJECT_ROOT%\%%F"
        if errorlevel 1 (
            echo FEHLER: %%F konnte nicht angelegt werden.
            endlocal & exit /b 1
        )
        echo Angelegt: %%F
    )
)

if not exist "%R4OS_PROJECT_ROOT%\Artifacts\" (
    mkdir "%R4OS_PROJECT_ROOT%\Artifacts"
    if errorlevel 1 (
        echo FEHLER: Artifacts konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Artifacts
)

if not exist "%R4OS_PROJECT_ROOT%\Artifacts\Distribution\Inputs\" (
    mkdir "%R4OS_PROJECT_ROOT%\Artifacts\Distribution\Inputs"
    if errorlevel 1 (
        echo FEHLER: Artifacts\Distribution\Inputs konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Artifacts\Distribution\Inputs
)

if not exist "%R4OS_PROJECT_ROOT%\Artifacts\Distribution\PrivateInjection\" (
    mkdir "%R4OS_PROJECT_ROOT%\Artifacts\Distribution\PrivateInjection"
    if errorlevel 1 (
        echo FEHLER: Artifacts\Distribution\PrivateInjection konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Artifacts\Distribution\PrivateInjection
)

if not exist "%R4OS_PROJECT_ROOT%\Artifacts\Modules\" (
    mkdir "%R4OS_PROJECT_ROOT%\Artifacts\Modules"
    if errorlevel 1 (
        echo FEHLER: Artifacts\Modules konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Artifacts\Modules
)

if not exist "%R4OS_PROJECT_ROOT%\Docs\" (
    mkdir "%R4OS_PROJECT_ROOT%\Docs"
    if errorlevel 1 (
        echo FEHLER: Docs konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Docs
)

if not exist "%R4OS_PROJECT_ROOT%\DevKit\" (
    mkdir "%R4OS_PROJECT_ROOT%\DevKit"
    if errorlevel 1 (
        echo FEHLER: DevKit konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: DevKit
)

if not exist "%R4OS_PROJECT_ROOT%\Repositories\" (
    mkdir "%R4OS_PROJECT_ROOT%\Repositories"
    if errorlevel 1 (
        echo FEHLER: Repositories konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Repositories
)

for %%D in (Apps Services Diagnostics Drivers Protocols Subsystems) do (
    if not exist "%R4OS_PROJECT_ROOT%\Repositories\%%D\" (
        mkdir "%R4OS_PROJECT_ROOT%\Repositories\%%D"
        if errorlevel 1 (
            echo FEHLER: Repositories\%%D konnte nicht erstellt werden.
            endlocal & exit /b 1
        )
        echo Angelegt: Repositories\%%D
    )
)

if not exist "%R4OS_CREDENTIAL_DIR%\" (
    mkdir "%R4OS_CREDENTIAL_DIR%"
    if errorlevel 1 (
        echo FEHLER: Tools\Credentials konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Tools\Credentials
)

if not exist "%R4OS_CREDENTIAL_FILE%" (
    >"%R4OS_CREDENTIAL_FILE%" (
        echo @echo off
        echo rem Lokale GitHub-Zugangsdaten fuer die R4OS-Werkzeuge.
        echo rem Nur Push und Repository-Verwaltung benoetigen diese Datei.
        echo rem Oeffentliche Pulls und Setups laufen ohne GitHub-Token.
        echo rem Diese Datei darf niemals in Git eingecheckt werden.
        echo.
        echo set "R4OS_GITHUB_USER=DEIN_GITHUB_BENUTZERNAME"
        echo set "R4OS_GITHUB_TOKEN=github_pat_DEIN_TOKEN"
        echo.
        echo exit /b 0
    )
    if errorlevel 1 (
        echo FEHLER: Tools\Credentials\Github.bat konnte nicht erstellt werden.
        endlocal & exit /b 1
    )
    echo Angelegt: Tools\Credentials\Github.bat
    echo Optional: Fuer Pushes Benutzername und Token in der Datei eintragen.
)

echo Oeffentliche GitHub-Pulls funktionieren ohne ausgefuellte Credentials.
echo Setup abgeschlossen.
endlocal & exit /b 0
