@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "R4OS_PROJECT_ROOT=%%~fI"

set "R4OS_CLEAN_ZIG_AFTER_ARTIFACTS="

if "%~1"=="" (
    set "R4OS_CLEAN_ZIG_AFTER_ARTIFACTS=1"
    goto clean_artifacts
)
if /I "%~1"=="-all" (
    if not "%~2"=="" goto usage_error
    set "R4OS_CLEAN_ZIG_AFTER_ARTIFACTS=1"
    goto clean_artifacts
)
if /I "%~1"=="-artifacts" (
    if not "%~2"=="" goto usage_error
    goto clean_artifacts
)
if /I "%~1"=="-zig" (
    if not "%~2"=="" goto usage_error
    goto clean_zig_caches
)
if /I "%~1"=="-zig-cache" (
    if not "%~2"=="" goto usage_error
    goto clean_zig_caches
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
    if defined R4OS_CLEAN_ZIG_AFTER_ARTIFACTS goto clean_zig_caches
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
call :remove_reparse_points "%R4OS_CLEAN_TARGET%"
if errorlevel 1 goto clean_failed

rd /S /Q "%R4OS_CLEAN_TARGET%" >nul 2>&1
if exist "%R4OS_CLEAN_TARGET%\" goto clean_failed

mkdir "%R4OS_CLEAN_TARGET%"
if errorlevel 1 goto create_failed

echo Artifacts wurde vollstaendig geleert.
if defined R4OS_CLEAN_ZIG_AFTER_ARTIFACTS goto clean_zig_caches
endlocal & exit /b 0

:clean_zig_caches
if not exist "%R4OS_PROJECT_ROOT%\.gitignore" goto unsafe_target

set "R4OS_CLEAN_ZIG_COUNT=0"
set "R4OS_CLEAN_ZIG_FAILED=0"

call :clean_zig_cache "%R4OS_PROJECT_ROOT%\.zig-cache"
if errorlevel 1 set "R4OS_CLEAN_ZIG_FAILED=1"
call :scan_zig_cache_root "%R4OS_PROJECT_ROOT%\Repositories"
if errorlevel 1 set "R4OS_CLEAN_ZIG_FAILED=1"
call :scan_zig_cache_root "%R4OS_PROJECT_ROOT%\Artifacts"
if errorlevel 1 set "R4OS_CLEAN_ZIG_FAILED=1"
call :scan_zig_cache_root "%R4OS_PROJECT_ROOT%\DevKit\SDK"
if errorlevel 1 set "R4OS_CLEAN_ZIG_FAILED=1"
call :scan_zig_cache_root "%R4OS_PROJECT_ROOT%\DevKit\HostTools"
if errorlevel 1 set "R4OS_CLEAN_ZIG_FAILED=1"

if "%R4OS_CLEAN_ZIG_FAILED%"=="1" goto zig_clean_failed
echo Zig-Caches entfernt: %R4OS_CLEAN_ZIG_COUNT%
endlocal & exit /b 0

:scan_zig_cache_root
if not exist "%~f1\" exit /b 0
set "R4OS_CLEAN_ZIG_SCAN_ROOT=%~f1"
for /F "delims=" %%I in ('dir /A:D /B /S "%R4OS_CLEAN_ZIG_SCAN_ROOT%\.zig-cache" 2^>nul') do (
    call :clean_zig_cache "%%~fI"
    if errorlevel 1 set "R4OS_CLEAN_ZIG_FAILED=1"
)
if "%R4OS_CLEAN_ZIG_FAILED%"=="1" exit /b 1
exit /b 0

:clean_zig_cache
if not exist "%~f1\" exit /b 0
set "R4OS_CLEAN_ZIG_TARGET=%~f1"
for %%I in ("%R4OS_CLEAN_ZIG_TARGET%") do (
    set "R4OS_CLEAN_ZIG_NAME=%%~nxI"
    set "R4OS_CLEAN_ZIG_ATTRIBUTES=%%~aI"
)
if /I not "%R4OS_CLEAN_ZIG_NAME%"==".zig-cache" goto unsafe_zig_cache

call :validate_cache_parent_chain "%R4OS_CLEAN_ZIG_TARGET%"
if errorlevel 1 goto unsafe_zig_cache

if not "%R4OS_CLEAN_ZIG_ATTRIBUTES:l=%"=="%R4OS_CLEAN_ZIG_ATTRIBUTES%" goto remove_zig_cache_link
fsutil reparsepoint query "%R4OS_CLEAN_ZIG_TARGET%" >nul 2>&1
if not errorlevel 1 goto remove_zig_cache_link

call :remove_reparse_points "%R4OS_CLEAN_ZIG_TARGET%"
if errorlevel 1 goto zig_cache_failed
rd /S /Q "%R4OS_CLEAN_ZIG_TARGET%" >nul 2>&1
if exist "%R4OS_CLEAN_ZIG_TARGET%\" goto zig_cache_failed
set /A R4OS_CLEAN_ZIG_COUNT+=1 >nul
echo Entfernt: %R4OS_CLEAN_ZIG_TARGET%
exit /b 0

:remove_zig_cache_link
call :remove_reparse_point "%R4OS_CLEAN_ZIG_TARGET%"
if errorlevel 1 goto zig_cache_failed
set /A R4OS_CLEAN_ZIG_COUNT+=1 >nul
echo Link entfernt: %R4OS_CLEAN_ZIG_TARGET%
exit /b 0

:validate_cache_parent_chain
for %%I in ("%~f1\..") do set "R4OS_CLEAN_PARENT_CURRENT=%%~fI"

:validate_cache_parent_loop
if /I "%R4OS_CLEAN_PARENT_CURRENT%"=="%R4OS_PROJECT_ROOT%" exit /b 0
if not exist "%R4OS_CLEAN_PARENT_CURRENT%\" exit /b 1
for %%I in ("%R4OS_CLEAN_PARENT_CURRENT%") do set "R4OS_CLEAN_PARENT_ATTRIBUTES=%%~aI"
if not "%R4OS_CLEAN_PARENT_ATTRIBUTES:l=%"=="%R4OS_CLEAN_PARENT_ATTRIBUTES%" exit /b 1
fsutil reparsepoint query "%R4OS_CLEAN_PARENT_CURRENT%" >nul 2>&1
if not errorlevel 1 exit /b 1
for %%I in ("%R4OS_CLEAN_PARENT_CURRENT%\..") do set "R4OS_CLEAN_PARENT_NEXT=%%~fI"
if /I "%R4OS_CLEAN_PARENT_NEXT%"=="%R4OS_CLEAN_PARENT_CURRENT%" exit /b 1
set "R4OS_CLEAN_PARENT_CURRENT=%R4OS_CLEAN_PARENT_NEXT%"
goto validate_cache_parent_loop

:remove_reparse_points
set "R4OS_CLEAN_REPARSE_ROOT=%~f1"
if not defined R4OS_CLEAN_REPARSE_ROOT exit /b 1
for /F "delims=" %%I in ('dir /A:L /B /S "%R4OS_CLEAN_REPARSE_ROOT%" 2^>nul') do (
    call :remove_reparse_point "%%~fI"
    if errorlevel 1 exit /b 1
)

set "R4OS_CLEAN_REPARSE_REMAINING=0"
for /F "delims=" %%I in ('dir /A:L /B /S "%R4OS_CLEAN_REPARSE_ROOT%" 2^>nul') do if exist "%%~fI" (
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

:unsafe_zig_cache
echo FEHLER: Unsicheres Zig-Cache-Ziel wurde nicht geloescht: %R4OS_CLEAN_ZIG_TARGET%
exit /b 1

:zig_cache_failed
echo FEHLER: Zig-Cache konnte nicht entfernt werden: %R4OS_CLEAN_ZIG_TARGET%
exit /b 1

:zig_clean_failed
echo FEHLER: Mindestens ein Zig-Cache konnte nicht sicher entfernt werden.
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
echo   Clean.bat -all
echo   Clean.bat -artifacts
echo   Clean.bat -zig
echo   Clean.bat -help
exit /b 0
