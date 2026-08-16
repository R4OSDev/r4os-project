@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "R4OS_PROJECT_ROOT=%%~fI"

if "%~1"=="" goto clean_artifacts
if /I "%~1"=="-artifacts" (
    if not "%~2"=="" goto usage_error
    goto clean_artifacts
)
if /I "%~1"=="-help" goto help
if /I "%~1"=="--help" goto help
if /I "%~1"=="/?" goto help
goto usage_error

:clean_artifacts
set "R4OS_CLEAN_TARGET=%R4OS_PROJECT_ROOT%\Artifacts"
for %%I in ("%R4OS_CLEAN_TARGET%") do set "R4OS_CLEAN_TARGET=%%~fI"
for %%I in ("%R4OS_CLEAN_TARGET%\..") do set "R4OS_CLEAN_PARENT=%%~fI"

if not exist "%R4OS_PROJECT_ROOT%\.gitignore" goto unsafe_target
if /I not "%R4OS_CLEAN_PARENT%"=="%R4OS_PROJECT_ROOT%" goto unsafe_target
if /I not "%R4OS_CLEAN_TARGET%"=="%R4OS_PROJECT_ROOT%\Artifacts" goto unsafe_target

if not exist "%R4OS_CLEAN_TARGET%\" (
    mkdir "%R4OS_CLEAN_TARGET%"
    if errorlevel 1 goto create_failed
    echo Artifacts war nicht vorhanden und wurde leer angelegt.
    endlocal & exit /b 0
)

for %%I in ("%R4OS_CLEAN_TARGET%") do set "R4OS_CLEAN_ROOT_ATTRIBUTES=%%~aI"
if not "%R4OS_CLEAN_ROOT_ATTRIBUTES:l=%"=="%R4OS_CLEAN_ROOT_ATTRIBUTES%" (
    echo FEHLER: Artifacts selbst ist ein Reparse-Link. Es wurde nichts geloescht.
    endlocal & exit /b 1
)
fsutil reparsepoint query "%R4OS_CLEAN_TARGET%" >nul 2>&1
if not errorlevel 1 (
    echo FEHLER: Artifacts selbst ist ein Reparse-Link. Es wurde nichts geloescht.
    endlocal & exit /b 1
)

echo Leere: %R4OS_CLEAN_TARGET%
call :remove_reparse_points
if errorlevel 1 goto clean_failed

rd /S /Q "%R4OS_CLEAN_TARGET%" >nul 2>&1
if exist "%R4OS_CLEAN_TARGET%\" goto clean_failed

mkdir "%R4OS_CLEAN_TARGET%"
if errorlevel 1 goto create_failed

echo Artifacts wurde vollstaendig geleert.
endlocal & exit /b 0

:remove_reparse_points
for /F "delims=" %%I in ('dir /A:L /B /S "%R4OS_CLEAN_TARGET%" 2^>nul') do (
    call :remove_reparse_point "%%~fI"
    if errorlevel 1 exit /b 1
)

set "R4OS_CLEAN_REPARSE_REMAINING=0"
for /F "delims=" %%I in ('dir /A:L /B /S "%R4OS_CLEAN_TARGET%" 2^>nul') do if exist "%%~fI" (
    echo FEHLER: Reparse-Link blieb erhalten: %%~fI
    set "R4OS_CLEAN_REPARSE_REMAINING=1"
)
if "%R4OS_CLEAN_REPARSE_REMAINING%"=="1" exit /b 1
exit /b 0

:remove_reparse_point
for %%I in ("%~1") do set "R4OS_CLEAN_ENTRY_ATTRIBUTES=%%~aI"
if /I "%R4OS_CLEAN_ENTRY_ATTRIBUTES:~0,1%"=="d" goto remove_reparse_directory

attrib -R -S -H "%~1" >nul 2>&1
del /F /Q "%~1" >nul 2>&1
fsutil reparsepoint query "%~1" >nul 2>&1
if not errorlevel 1 exit /b 1
if exist "%~1" exit /b 1
exit /b 0

:remove_reparse_directory
rd "%~1" >nul 2>&1
fsutil reparsepoint query "%~1" >nul 2>&1
if not errorlevel 1 exit /b 1
if exist "%~1\" exit /b 1
exit /b 0

:unsafe_target
echo FEHLER: Das berechnete Clean-Ziel liegt nicht sicher im Projektworkspace.
endlocal & exit /b 1

:clean_failed
echo FEHLER: Artifacts konnte nicht vollstaendig geleert werden.
echo Verbliebene Eintraege:
dir /A /B "%R4OS_CLEAN_TARGET%" 2>nul
endlocal & exit /b 1

:create_failed
echo FEHLER: Der leere Artifacts-Ordner konnte nicht angelegt werden.
endlocal & exit /b 1

:help
call :usage
endlocal & exit /b 0

:usage_error
call :usage
endlocal & exit /b 1

:usage
echo Verwendung:
echo   Clean.bat
echo   Clean.bat -artifacts
echo   Clean.bat -help
exit /b 0
