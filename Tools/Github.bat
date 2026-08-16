@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "R4OS_PROJECT_ROOT=%%~fI"
set "R4OS_GITHUB_ORGANIZATION=R4OSDev"

if defined R4OS_GITHUB_ASKPASS goto askpass

if /I "%~1"=="-push" set "R4OS_ACTION=PUSH"
if /I "%~1"=="-pull" set "R4OS_ACTION=PULL"

set "R4OS_COMPONENT_NAME=%~3"
set "R4OS_COMMIT_MESSAGE=%~3"
if /I "%~2"=="-app" set "R4OS_COMMIT_MESSAGE=%~4"
if /I "%~2"=="-service" set "R4OS_COMMIT_MESSAGE=%~4"
if /I "%~2"=="-diagnostic" set "R4OS_COMMIT_MESSAGE=%~4"
if /I "%~2"=="-driver" set "R4OS_COMMIT_MESSAGE=%~4"
if /I "%~2"=="-protocol" set "R4OS_COMMIT_MESSAGE=%~4"

if not defined R4OS_ACTION if "%~1"=="" goto interactive
if not defined R4OS_ACTION goto usage

call :select_repository "%~2"
if errorlevel 1 goto usage

if /I "%R4OS_ACTION%"=="PUSH" goto upload
goto pull

:interactive
echo.
echo GitHub-Aktion auswaehlen:
echo   [1] Push
echo   [2] Pull
choice /C 12 /N /M "Auswahl"
if errorlevel 2 set "R4OS_INTERACTIVE_ACTION=-pull"
if errorlevel 1 if not defined R4OS_INTERACTIVE_ACTION set "R4OS_INTERACTIVE_ACTION=-push"

echo.
echo Repository auswaehlen:
echo   [1] Project
echo   [2] DevKit
echo   [3] Contract
echo   [4] SDK
echo   [5] Libraries
echo   [6] Kernel
echo   [7] Distribution
echo   [8] Anwendung
echo   [9] Treiber
echo   [A] Protokoll
echo   [B] Dienst
echo   [C] Diagnose
echo   [D] Docs
echo   [E] Organisationsprofil
choice /C 123456789ABCDE /N /M "Auswahl"
if errorlevel 14 set "R4OS_INTERACTIVE_TARGET=-organization"
if errorlevel 13 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-docs"
if errorlevel 12 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-diagnostic"
if errorlevel 11 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-service"
if errorlevel 10 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-protocol"
if errorlevel 9 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-driver"
if errorlevel 8 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-app"
if errorlevel 7 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-distribution"
if errorlevel 6 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-kernel"
if errorlevel 5 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-libraries"
if errorlevel 4 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-sdk"
if errorlevel 3 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-contract"
if errorlevel 2 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-devkit"
if errorlevel 1 if not defined R4OS_INTERACTIVE_TARGET set "R4OS_INTERACTIVE_TARGET=-project"

if /I "%R4OS_INTERACTIVE_TARGET%"=="-app" goto interactive_component
if /I "%R4OS_INTERACTIVE_TARGET%"=="-service" goto interactive_component
if /I "%R4OS_INTERACTIVE_TARGET%"=="-diagnostic" goto interactive_component
if /I "%R4OS_INTERACTIVE_TARGET%"=="-driver" goto interactive_component
if /I "%R4OS_INTERACTIVE_TARGET%"=="-protocol" goto interactive_component

call "%~f0" %R4OS_INTERACTIVE_ACTION% %R4OS_INTERACTIVE_TARGET%
set "R4OS_INTERACTIVE_EXIT=%ERRORLEVEL%"
endlocal & exit /b %R4OS_INTERACTIVE_EXIT%

:interactive_component
echo.
set /p "R4OS_INTERACTIVE_COMPONENT=Komponentenname: "
if not defined R4OS_INTERACTIVE_COMPONENT (
    echo FEHLER: Ein Komponentenname ist erforderlich.
    endlocal & exit /b 1
)
call "%~f0" %R4OS_INTERACTIVE_ACTION% %R4OS_INTERACTIVE_TARGET% "%R4OS_INTERACTIVE_COMPONENT%"
set "R4OS_INTERACTIVE_EXIT=%ERRORLEVEL%"
endlocal & exit /b %R4OS_INTERACTIVE_EXIT%

:select_repository
if /I "%~1"=="-project" goto select_project
if /I "%~1"=="-devkit" goto select_devkit
if /I "%~1"=="-contract" goto select_contract
if /I "%~1"=="-sdk" goto select_sdk
if /I "%~1"=="-libraries" goto select_libraries
if /I "%~1"=="-kernel" goto select_kernel
if /I "%~1"=="-distribution" goto select_distribution
if /I "%~1"=="-docs" goto select_docs
if /I "%~1"=="-organization" goto select_organization
if /I "%~1"=="-app" goto select_app
if /I "%~1"=="-service" goto select_service
if /I "%~1"=="-diagnostic" goto select_diagnostic
if /I "%~1"=="-driver" goto select_driver
if /I "%~1"=="-protocol" goto select_protocol
exit /b 1

:select_project
set "R4OS_REPOSITORY_KEY=project"
set "R4OS_REPOSITORY_LABEL=Project"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%"
set "R4OS_REPOSITORY_NAME=r4os-project"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-project.git"
set "R4OS_REPOSITORY_DESCRIPTION=R4OS multi-repository project workspace."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=0"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Projektstand sichern"
exit /b 0

:select_devkit
set "R4OS_REPOSITORY_KEY=devkit"
set "R4OS_REPOSITORY_LABEL=DevKit"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\DevKit"
set "R4OS_REPOSITORY_NAME=r4os-devkit"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-devkit.git"
set "R4OS_REPOSITORY_DESCRIPTION=Cross-platform bootstrap and setup scripts for the R4OS development kit."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=DevKit-Stand sichern"
exit /b 0

:select_contract
set "R4OS_REPOSITORY_KEY=contract"
set "R4OS_REPOSITORY_LABEL=Contract"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\Contract"
set "R4OS_REPOSITORY_NAME=r4os-contract"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-contract.git"
set "R4OS_REPOSITORY_DESCRIPTION=Canonical API and ABI contract for R4OS."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Contract-Stand sichern"
exit /b 0

:select_sdk
set "R4OS_REPOSITORY_KEY=sdk"
set "R4OS_REPOSITORY_LABEL=SDK"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\SDK"
set "R4OS_REPOSITORY_NAME=r4os-sdk"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-sdk.git"
set "R4OS_REPOSITORY_DESCRIPTION=Host-neutral SDK and platform bindings for R4OS."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=SDK-Stand sichern"
exit /b 0

:select_libraries
set "R4OS_REPOSITORY_KEY=libraries"
set "R4OS_REPOSITORY_LABEL=Libraries"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\Libraries"
set "R4OS_REPOSITORY_NAME=r4os-libraries"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-libraries.git"
set "R4OS_REPOSITORY_DESCRIPTION=Official independent runtime libraries for R4OS."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Library-Stand sichern"
exit /b 0

:select_kernel
set "R4OS_REPOSITORY_KEY=kernel"
set "R4OS_REPOSITORY_LABEL=Kernel"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\Kernel"
set "R4OS_REPOSITORY_NAME=r4os-kernel"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-kernel.git"
set "R4OS_REPOSITORY_DESCRIPTION=R4OS kernel, boot integration and kernel-owned tests."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Kernel-Stand sichern"
exit /b 0

:select_distribution
set "R4OS_REPOSITORY_KEY=distribution"
set "R4OS_REPOSITORY_LABEL=Distribution"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\Distribution"
set "R4OS_REPOSITORY_NAME=r4os-distribution"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-distribution.git"
set "R4OS_REPOSITORY_DESCRIPTION=R4OS image assembly, release configuration and distribution-owned host tools."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Distribution-Stand sichern"
exit /b 0

:select_docs
set "R4OS_REPOSITORY_KEY=docs"
set "R4OS_REPOSITORY_LABEL=Docs"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Docs"
set "R4OS_REPOSITORY_NAME=r4os-docs"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/r4os-docs.git"
set "R4OS_REPOSITORY_DESCRIPTION=R4OS project documentation and inventories."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Dokumentationsstand sichern"
exit /b 0

:select_organization
set "R4OS_REPOSITORY_KEY=organization"
set "R4OS_REPOSITORY_LABEL=Organisationsprofil"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\Organization"
set "R4OS_REPOSITORY_NAME=.github"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/.github.git"
set "R4OS_REPOSITORY_DESCRIPTION=Public R4OS organization profile and community metadata."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=Organisationsprofil aktualisieren"
exit /b 0

:select_app
set "R4OS_COMPONENT_KIND=app"
set "R4OS_COMPONENT_LABEL=Anwendung"
set "R4OS_COMPONENT_DESCRIPTION=Independent R4OS application"
set "R4OS_COMPONENT_DIRECTORY=Apps"
goto select_component

:select_service
set "R4OS_COMPONENT_KIND=service"
set "R4OS_COMPONENT_LABEL=Dienst"
set "R4OS_COMPONENT_DESCRIPTION=Independent R4OS service"
set "R4OS_COMPONENT_DIRECTORY=Services"
goto select_component

:select_diagnostic
set "R4OS_COMPONENT_KIND=diagnostic"
set "R4OS_COMPONENT_LABEL=Diagnose"
set "R4OS_COMPONENT_DESCRIPTION=Independent R4OS diagnostic"
set "R4OS_COMPONENT_DIRECTORY=Diagnostics"
goto select_component

:select_driver
set "R4OS_COMPONENT_KIND=driver"
set "R4OS_COMPONENT_LABEL=Treiber"
set "R4OS_COMPONENT_DESCRIPTION=Independent R4OS driver module"
set "R4OS_COMPONENT_DIRECTORY=Drivers"
goto select_component

:select_protocol
set "R4OS_COMPONENT_KIND=protocol"
set "R4OS_COMPONENT_LABEL=Protokoll"
set "R4OS_COMPONENT_DESCRIPTION=Independent R4OS protocol module"
set "R4OS_COMPONENT_DIRECTORY=Protocols"
goto select_component

:select_component
if not defined R4OS_COMPONENT_NAME (
    echo FEHLER: Fuer -%R4OS_COMPONENT_KIND% ist ein Komponentenname erforderlich.
    exit /b 1
)

set "R4OS_COMPONENT_SLUG="
for /f "usebackq delims=" %%N in (`powershell.exe -NoProfile -Command "$value = $env:R4OS_COMPONENT_NAME; if ($value -cnotmatch '^[A-Za-z0-9][A-Za-z0-9-]*$') { exit 1 }; $value.ToLowerInvariant()"`) do set "R4OS_COMPONENT_SLUG=%%N"
if not defined R4OS_COMPONENT_SLUG (
    echo FEHLER: Der Komponentenname darf nur Buchstaben, Ziffern und Bindestriche enthalten.
    exit /b 1
)

set "R4OS_REPOSITORY_KEY=%R4OS_COMPONENT_KIND%-%R4OS_COMPONENT_SLUG%"
set "R4OS_REPOSITORY_LABEL=%R4OS_COMPONENT_LABEL% %R4OS_COMPONENT_NAME%"
set "R4OS_REPOSITORY_ROOT=%R4OS_PROJECT_ROOT%\Repositories\%R4OS_COMPONENT_DIRECTORY%\%R4OS_COMPONENT_NAME%"
set "R4OS_REPOSITORY_NAME=r4os-%R4OS_COMPONENT_KIND%-%R4OS_COMPONENT_SLUG%"
set "R4OS_REPOSITORY_REMOTE=https://github.com/%R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME%.git"
set "R4OS_REPOSITORY_DESCRIPTION=%R4OS_COMPONENT_DESCRIPTION% %R4OS_COMPONENT_NAME%."
set "R4OS_REPOSITORY_PRIVATE=false"
set "R4OS_REPOSITORY_ALLOW_INIT=1"
set "R4OS_DEFAULT_COMMIT_MESSAGE=%R4OS_COMPONENT_NAME%-Stand sichern"
exit /b 0

:pull
call :load_credentials
if errorlevel 1 goto failure

call :ensure_local_repository
if errorlevel 1 goto failure

call :verify_main_branch
if errorlevel 1 goto failure

call :github_repository_exists
if errorlevel 1 (
    echo FEHLER: %R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME% ist auf GitHub nicht erreichbar.
    goto failure
)

call :ensure_local_remote
if errorlevel 1 goto failure

set "GIT_ASKPASS=%~f0"
set "R4OS_GITHUB_ASKPASS=1"
set "GIT_TERMINAL_PROMPT=0"

git -C "%R4OS_REPOSITORY_ROOT%" pull --ff-only origin main
if errorlevel 1 (
    echo FEHLER: %R4OS_REPOSITORY_LABEL% konnte nicht von GitHub gepullt werden.
    goto failure
)

echo ERFOLG: %R4OS_REPOSITORY_ROOT% wurde von %R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME% aktualisiert.
endlocal & exit /b 0

:upload
call :load_credentials
if errorlevel 1 goto failure

if "%R4OS_COMMIT_MESSAGE%"=="" set "R4OS_COMMIT_MESSAGE=%R4OS_DEFAULT_COMMIT_MESSAGE%"

call :ensure_local_repository
if errorlevel 1 goto failure

call :verify_main_branch
if errorlevel 1 goto failure

call :ensure_github_repository
if errorlevel 1 goto failure

call :ensure_local_remote
if errorlevel 1 goto failure

set "GIT_ASKPASS=%~f0"
set "R4OS_GITHUB_ASKPASS=1"
set "GIT_TERMINAL_PROMPT=0"

git -C "%R4OS_REPOSITORY_ROOT%" add -A
if errorlevel 1 (
    echo FEHLER: Dateien in %R4OS_REPOSITORY_LABEL% konnten nicht gestaged werden.
    goto failure
)

git -C "%R4OS_REPOSITORY_ROOT%" diff --cached --quiet
if errorlevel 1 goto commit
echo Keine neuen Dateien in %R4OS_REPOSITORY_LABEL% zum Committen.
goto pushbranch

:commit
call :ensure_identity
if errorlevel 1 goto failure

git -C "%R4OS_REPOSITORY_ROOT%" commit -m "%R4OS_COMMIT_MESSAGE%"
if errorlevel 1 (
    echo FEHLER: Der Commit fuer %R4OS_REPOSITORY_LABEL% konnte nicht erstellt werden.
    goto failure
)

:pushbranch
git -C "%R4OS_REPOSITORY_ROOT%" push -u origin main
if errorlevel 1 (
    echo FEHLER: %R4OS_REPOSITORY_LABEL% konnte nicht nach GitHub gepusht werden.
    goto failure
)

echo ERFOLG: %R4OS_REPOSITORY_ROOT% wurde nach %R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME% gepusht.
endlocal & exit /b 0

:ensure_local_repository
if exist "%R4OS_REPOSITORY_ROOT%\.git" exit /b 0

if /I not "%R4OS_REPOSITORY_ALLOW_INIT%"=="1" (
    echo FEHLER: %R4OS_REPOSITORY_ROOT% ist kein Git-Repository.
    exit /b 1
)

if not exist "%R4OS_REPOSITORY_ROOT%" (
    mkdir "%R4OS_REPOSITORY_ROOT%" >nul 2>&1
    if errorlevel 1 (
        echo FEHLER: %R4OS_REPOSITORY_ROOT% konnte nicht erstellt werden.
        exit /b 1
    )
)

git -C "%R4OS_REPOSITORY_ROOT%" init -b main
if errorlevel 1 (
    echo FEHLER: %R4OS_REPOSITORY_LABEL% konnte nicht als Git-Repository initialisiert werden.
    exit /b 1
)

echo %R4OS_REPOSITORY_LABEL% wurde lokal als Git-Repository initialisiert.
exit /b 0

:verify_main_branch
set "R4OS_REPOSITORY_BRANCH="
for /f "delims=" %%B in ('git -C "%R4OS_REPOSITORY_ROOT%" branch --show-current') do set "R4OS_REPOSITORY_BRANCH=%%B"
if /I "%R4OS_REPOSITORY_BRANCH%"=="main" exit /b 0

echo FEHLER: %R4OS_REPOSITORY_LABEL% muss auf dem Branch main stehen.
exit /b 1

:ensure_local_remote
git -C "%R4OS_REPOSITORY_ROOT%" remote get-url origin >nul 2>&1
if errorlevel 1 goto add_local_remote

call :verify_local_remote
exit /b %ERRORLEVEL%

:verify_local_remote
set "R4OS_CURRENT_REMOTE="
for /f "delims=" %%R in ('git -C "%R4OS_REPOSITORY_ROOT%" remote get-url origin') do set "R4OS_CURRENT_REMOTE=%%R"
if /I "%R4OS_CURRENT_REMOTE%"=="%R4OS_REPOSITORY_REMOTE%" exit /b 0

echo FEHLER: origin zeigt auf %R4OS_CURRENT_REMOTE% statt auf %R4OS_REPOSITORY_REMOTE%.
exit /b 1

:add_local_remote
git -C "%R4OS_REPOSITORY_ROOT%" remote add origin "%R4OS_REPOSITORY_REMOTE%"
if errorlevel 1 (
    echo FEHLER: Das GitHub-Remote konnte in %R4OS_REPOSITORY_LABEL% nicht eingetragen werden.
    exit /b 1
)
exit /b 0

:github_repository_exists
curl.exe --silent --show-error --fail --request GET --header "Accept: application/vnd.github+json" --header "Authorization: Bearer %R4OS_GITHUB_TOKEN%" "https://api.github.com/repos/%R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME%" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:ensure_github_repository
call :github_repository_exists
if not errorlevel 1 exit /b 0

echo GitHub-Repository %R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME% wird erstellt.
set "R4OS_GITHUB_API_RESPONSE=%TEMP%\R4OS-GitHub-%R4OS_REPOSITORY_KEY%-%RANDOM%.json"
curl.exe --silent --show-error --fail-with-body --request POST --header "Accept: application/vnd.github+json" --header "Content-Type: application/json" --header "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer %R4OS_GITHUB_TOKEN%" "https://api.github.com/orgs/%R4OS_GITHUB_ORGANIZATION%/repos" --data "{\"name\":\"%R4OS_REPOSITORY_NAME%\",\"description\":\"%R4OS_REPOSITORY_DESCRIPTION%\",\"private\":%R4OS_REPOSITORY_PRIVATE%}" --output "%R4OS_GITHUB_API_RESPONSE%"
if errorlevel 1 (
    echo FEHLER: Das GitHub-Repository %R4OS_GITHUB_ORGANIZATION%/%R4OS_REPOSITORY_NAME% konnte nicht erstellt werden.
    if exist "%R4OS_GITHUB_API_RESPONSE%" type "%R4OS_GITHUB_API_RESPONSE%"
    if exist "%R4OS_GITHUB_API_RESPONSE%" del /q "%R4OS_GITHUB_API_RESPONSE%"
    exit /b 1
)
if exist "%R4OS_GITHUB_API_RESPONSE%" del /q "%R4OS_GITHUB_API_RESPONSE%"
exit /b 0

:ensure_identity
git -C "%R4OS_REPOSITORY_ROOT%" config --get user.name >nul 2>&1
if errorlevel 1 git -C "%R4OS_REPOSITORY_ROOT%" config user.name "%R4OS_GITHUB_USER%"

git -C "%R4OS_REPOSITORY_ROOT%" config --get user.email >nul 2>&1
if errorlevel 1 git -C "%R4OS_REPOSITORY_ROOT%" config user.email "%R4OS_GITHUB_USER%@users.noreply.github.com"
exit /b 0

:load_credentials
if not exist "%~dp0Credentials\Github.bat" (
    echo FEHLER: Tools\Credentials\Github.bat fehlt.
    echo Bitte zuerst Tools\Setup.bat ausfuehren.
    exit /b 1
)

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
if /I "%R4OS_GITHUB_USER%"=="DEIN_GITHUB_BENUTZERNAME" (
    echo FEHLER: Bitte R4OS_GITHUB_USER in Tools\Credentials\Github.bat eintragen.
    exit /b 1
)
if /I "%R4OS_GITHUB_TOKEN%"=="github_pat_DEIN_TOKEN" (
    echo FEHLER: Bitte R4OS_GITHUB_TOKEN in Tools\Credentials\Github.bat eintragen.
    exit /b 1
)
exit /b 0

:askpass
call :load_credentials
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
echo   Github.bat -push -devkit ["Commit-Beschreibung"]
echo   Github.bat -pull -devkit
echo   Github.bat -push -contract ["Commit-Beschreibung"]
echo   Github.bat -pull -contract
echo   Github.bat -push -sdk ["Commit-Beschreibung"]
echo   Github.bat -pull -sdk
echo   Github.bat -push -libraries ["Commit-Beschreibung"]
echo   Github.bat -pull -libraries
echo   Github.bat -push -kernel ["Commit-Beschreibung"]
echo   Github.bat -pull -kernel
echo   Github.bat -push -distribution ["Commit-Beschreibung"]
echo   Github.bat -pull -distribution
echo   Github.bat -push -docs ["Commit-Beschreibung"]
echo   Github.bat -pull -docs
echo   Github.bat -push -organization ["Commit-Beschreibung"]
echo   Github.bat -pull -organization
echo   Github.bat -push -app NAME ["Commit-Beschreibung"]
echo   Github.bat -pull -app NAME
echo   Github.bat -push -service NAME ["Commit-Beschreibung"]
echo   Github.bat -pull -service NAME
echo   Github.bat -push -diagnostic NAME ["Commit-Beschreibung"]
echo   Github.bat -pull -diagnostic NAME
echo   Github.bat -push -driver NAME ["Commit-Beschreibung"]
echo   Github.bat -pull -driver NAME
echo   Github.bat -push -protocol NAME ["Commit-Beschreibung"]
echo   Github.bat -pull -protocol NAME
endlocal & exit /b 1

:failure
endlocal & exit /b 1
