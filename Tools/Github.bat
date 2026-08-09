@echo off
setlocal EnableExtensions DisableDelayedExpansion

if /I "%~1"=="--askpass" goto askpass
if /I "%~1"=="-push" if /I "%~2"=="-project" goto push_project
goto usage

:push_project
call :load_credentials
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

call :ensure_project_remote
if errorlevel 1 goto failure

set "GIT_ASKPASS=%~f0 --askpass"
set "GIT_TERMINAL_PROMPT=0"

git -C "%R4OS_PROJECT_ROOT%" add -A
if errorlevel 1 (
    echo FEHLER: Dateien konnten nicht gestaged werden.
    goto failure
)

git -C "%R4OS_PROJECT_ROOT%" diff --cached --quiet
if errorlevel 1 goto commit_project
echo Keine neuen Projektdateien zum Committen.
goto push_project_branch

:commit_project
call :ensure_identity
if errorlevel 1 goto failure

git -C "%R4OS_PROJECT_ROOT%" commit -m "%R4OS_COMMIT_MESSAGE%"
if errorlevel 1 (
    echo FEHLER: Der Projektcommit konnte nicht erstellt werden.
    goto failure
)

:push_project_branch
git -C "%R4OS_PROJECT_ROOT%" push -u origin main
if errorlevel 1 (
    echo FEHLER: Der Projektstand konnte nicht nach GitHub gepusht werden.
    goto failure
)

echo ERFOLG: D:\R4OS wurde nach R4OSDev/r4os-project gepusht.
endlocal & exit /b 0

:ensure_project_remote
git -C "%R4OS_PROJECT_ROOT%" remote get-url origin >nul 2>&1
if errorlevel 1 goto create_project_remote

for /f "delims=" %%R in ('git -C "%R4OS_PROJECT_ROOT%" remote get-url origin') do set "R4OS_CURRENT_REMOTE=%%R"
if /I "%R4OS_CURRENT_REMOTE%"=="%R4OS_PROJECT_REMOTE%" exit /b 0

echo FEHLER: origin zeigt auf %R4OS_CURRENT_REMOTE% statt auf %R4OS_PROJECT_REMOTE%.
exit /b 1

:create_project_remote
call :ensure_github_project
if errorlevel 1 exit /b 1

git -C "%R4OS_PROJECT_ROOT%" remote add origin "%R4OS_PROJECT_REMOTE%"
if errorlevel 1 (
    echo FEHLER: Das GitHub-Remote konnte lokal nicht eingetragen werden.
    exit /b 1
)
exit /b 0

:ensure_github_project
curl.exe --silent --show-error --fail --request GET --header "Accept: application/vnd.github+json" --header "Authorization: Bearer %R4OS_GITHUB_TOKEN%" "https://api.github.com/repos/R4OSDev/r4os-project" >nul 2>&1
if not errorlevel 1 exit /b 0

echo GitHub-Repository R4OSDev/r4os-project wird erstellt.
curl.exe --silent --show-error --fail --request POST --header "Accept: application/vnd.github+json" --header "Authorization: Bearer %R4OS_GITHUB_TOKEN%" "https://api.github.com/orgs/R4OSDev/repos" --data "{\"name\":\"r4os-project\",\"description\":\"Private R4OS project workspace for Windows.\",\"private\":true}" >nul
if errorlevel 1 (
    echo FEHLER: Das private GitHub-Repository konnte nicht erstellt werden.
    exit /b 1
)
exit /b 0

:ensure_identity
git -C "%R4OS_PROJECT_ROOT%" config --get user.name >nul 2>&1
if errorlevel 1 git -C "%R4OS_PROJECT_ROOT%" config user.name "%R4OS_GITHUB_USER%"

git -C "%R4OS_PROJECT_ROOT%" config --get user.email >nul 2>&1
if errorlevel 1 git -C "%R4OS_PROJECT_ROOT%" config user.email "%R4OS_GITHUB_USER%@users.noreply.github.com"
exit /b 0

:load_credentials
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
call :load_credentials
if errorlevel 1 exit /b 1

echo %~2 | findstr /I /C:"Username" >nul
if not errorlevel 1 (
    echo %R4OS_GITHUB_USER%
    endlocal & exit /b 0
)

echo %R4OS_GITHUB_TOKEN%
endlocal & exit /b 0

:usage
echo Verwendung: Github.bat -push -project ["Commit-Beschreibung"]
endlocal & exit /b 1

:failure
endlocal & exit /b 1
