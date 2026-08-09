@echo off
setlocal EnableExtensions DisableDelayedExpansion

if defined R4OS_GITHUB_ASKPASS goto askpass
if /I "%~1"=="-push" if /I "%~2"=="-project" set "R4OS_ACTION=PUSH"
if /I "%~1"=="-pull" if /I "%~2"=="-project" set "R4OS_ACTION=PULL"
if defined R4OS_ACTION goto pull
if "%~1"=="" goto interactive
goto usage

:interactive
echo.
echo GitHub-Aktion auswaehlen:
echo   [1] Push
echo   [2] Pull
choice /C 12 /N /M "Auswahl"
if errorlevel 2 set "R4OS_INTERACTIVE_ACTION=-pull"
if errorlevel 1 if not defined R4OS_INTERACTIVE_ACTION set "R4OS_INTERACTIVE_ACTION=-push"

echo.
echo Projekt auswaehlen:
echo   [1] Project
choice /C 1 /N /M "Auswahl"

call "%~f0" %R4OS_INTERACTIVE_ACTION% -project
endlocal & exit /b %errorlevel%

:pull
if /I "%R4OS_ACTION%"=="PUSH" goto upload
call :loadcredentials
if errorlevel 1 goto failure

set "R4OS_PROJECT_ROOT=D:\R4OS"
set "R4OS_PROJECT_REMOTE=https://github.com/R4OSDev/r4os-project.git"

if not exist "%R4OS_PROJECT_ROOT%\.git" (
    echo FEHLER: %R4OS_PROJECT_ROOT% ist kein Git-Repository.
    goto failure
)

for /f "delims=" %%B in ('git -C "%R4OS_PROJECT_ROOT%" branch --show-current') do set "R4OS_PROJECT_BRANCH=%%B"
if /I not "%R4OS_PROJECT_BRANCH%"=="main" (
    echo FEHLER: Das Projekt-Repository muss auf dem Branch main stehen.
    goto failure
)

call :verifyremote
if errorlevel 1 goto failure

set "GIT_ASKPASS=%~f0"
set "R4OS_GITHUB_ASKPASS=1"
set "GIT_TERMINAL_PROMPT=0"

git -C "%R4OS_PROJECT_ROOT%" pull --ff-only origin main
if errorlevel 1 (
    echo FEHLER: Der Projektstand konnte nicht von GitHub gepullt werden.
    goto failure
)

echo ERFOLG: D:\R4OS wurde von R4OSDev/r4os-project aktualisiert.
endlocal & exit /b 0

:upload
call :loadcredentials
if errorlevel 1 goto failure

set "R4OS_PROJECT_ROOT=D:\R4OS"
set "R4OS_PROJECT_REMOTE=https://github.com/R4OSDev/r4os-project.git"
set "R4OS_COMMIT_MESSAGE=%~3"
if "%R4OS_COMMIT_MESSAGE%"=="" set "R4OS_COMMIT_MESSAGE=Projektstand sichern"

if not exist "%R4OS_PROJECT_ROOT%\.git" (
    echo FEHLER: %R4OS_PROJECT_ROOT% ist kein Git-Repository.
    goto failure
)

for /f "delims=" %%B in ('git -C "%R4OS_PROJECT_ROOT%" branch --show-current') do set "R4OS_PROJECT_BRANCH=%%B"
if /I not "%R4OS_PROJECT_BRANCH%"=="main" (
    echo FEHLER: Das Projekt-Repository muss auf dem Branch main stehen.
    goto failure
)

call :ensureremote
if errorlevel 1 goto failure

set "GIT_ASKPASS=%~f0"
set "R4OS_GITHUB_ASKPASS=1"
set "GIT_TERMINAL_PROMPT=0"

git -C "%R4OS_PROJECT_ROOT%" add -A
if errorlevel 1 (
    echo FEHLER: Dateien konnten nicht gestaged werden.
    goto failure
)

git -C "%R4OS_PROJECT_ROOT%" diff --cached --quiet
if errorlevel 1 goto commit
echo Keine neuen Projektdateien zum Committen.
goto pushbranch

:commit
call :ensureidentity
if errorlevel 1 goto failure

git -C "%R4OS_PROJECT_ROOT%" commit -m "%R4OS_COMMIT_MESSAGE%"
if errorlevel 1 (
    echo FEHLER: Der Projektcommit konnte nicht erstellt werden.
    goto failure
)

:pushbranch
git -C "%R4OS_PROJECT_ROOT%" push -u origin main
if errorlevel 1 (
    echo FEHLER: Der Projektstand konnte nicht nach GitHub gepusht werden.
    goto failure
)

echo ERFOLG: D:\R4OS wurde nach R4OSDev/r4os-project gepusht.
endlocal & exit /b 0

:ensureremote
git -C "%R4OS_PROJECT_ROOT%" remote get-url origin >nul 2>&1
if errorlevel 1 goto createremote

call :verifyremote
exit /b %errorlevel%

:verifyremote
git -C "%R4OS_PROJECT_ROOT%" remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo FEHLER: Das Projekt-Repository besitzt kein Remote namens origin.
    exit /b 1
)

for /f "delims=" %%R in ('git -C "%R4OS_PROJECT_ROOT%" remote get-url origin') do set "R4OS_CURRENT_REMOTE=%%R"
if /I "%R4OS_CURRENT_REMOTE%"=="%R4OS_PROJECT_REMOTE%" exit /b 0

echo FEHLER: origin zeigt auf %R4OS_CURRENT_REMOTE% statt auf %R4OS_PROJECT_REMOTE%.
exit /b 1

:createremote
call :ensuregithub
if errorlevel 1 exit /b 1

git -C "%R4OS_PROJECT_ROOT%" remote add origin "%R4OS_PROJECT_REMOTE%"
if errorlevel 1 (
    echo FEHLER: Das GitHub-Remote konnte lokal nicht eingetragen werden.
    exit /b 1
)
exit /b 0

:ensuregithub
curl.exe --silent --show-error --fail --request GET --header "Accept: application/vnd.github+json" --header "Authorization: Bearer %R4OS_GITHUB_TOKEN%" "https://api.github.com/repos/R4OSDev/r4os-project" >nul 2>&1
if not errorlevel 1 exit /b 0

echo GitHub-Repository R4OSDev/r4os-project wird erstellt.
curl.exe --silent --show-error --fail --request POST --header "Accept: application/vnd.github+json" --header "Authorization: Bearer %R4OS_GITHUB_TOKEN%" "https://api.github.com/orgs/R4OSDev/repos" --data "{\"name\":\"r4os-project\",\"description\":\"Private R4OS project workspace for Windows.\",\"private\":true}" >nul
if errorlevel 1 (
    echo FEHLER: Das private GitHub-Repository konnte nicht erstellt werden.
    exit /b 1
)
exit /b 0

:ensureidentity
git -C "%R4OS_PROJECT_ROOT%" config --get user.name >nul 2>&1
if errorlevel 1 git -C "%R4OS_PROJECT_ROOT%" config user.name "%R4OS_GITHUB_USER%"

git -C "%R4OS_PROJECT_ROOT%" config --get user.email >nul 2>&1
if errorlevel 1 git -C "%R4OS_PROJECT_ROOT%" config user.email "%R4OS_GITHUB_USER%@users.noreply.github.com"
exit /b 0

:loadcredentials
call "%~dp0Credentials\Github.bat"
if errorlevel 1 (
    echo FEHLER: Die GitHub-Zugangsdaten konnten nicht geladen werden.
    exit /b 1
)

if not defined R4OS_GITHUB_USER (
    echo FEHLER: R4OS_GITHUB_USER fehlt in Tools\Credentials\Github.bat.
    exit /b 1
)
if not defined R4OS_GITHUB_TOKEN (
    echo FEHLER: R4OS_GITHUB_TOKEN fehlt in Tools\Credentials\Github.bat.
    exit /b 1
)
exit /b 0

:askpass
call :loadcredentials
if errorlevel 1 exit /b 1

echo %~1 | findstr /I /C:"Username" >nul
if not errorlevel 1 (
    echo %R4OS_GITHUB_USER%
    endlocal & exit /b 0
)

echo %R4OS_GITHUB_TOKEN%
endlocal & exit /b 0

:usage
echo Verwendung:
echo   Github.bat
echo   Github.bat -push -project ["Commit-Beschreibung"]
echo   Github.bat -pull -project
endlocal & exit /b 1

:failure
endlocal & exit /b 1
