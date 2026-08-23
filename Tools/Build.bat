@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "R4OS_WORKSPACE_ROOT=%%~fI"
set "R4OS_BUILD_HELPER=%~dp0BuildWorkspace.ps1"
set "R4OS_INTERACTIVE=0"

if not exist "%R4OS_BUILD_HELPER%" (
    echo FEHLER: Build-Helfer fehlt: "%R4OS_BUILD_HELPER%"
    exit /b 1
)

if "%~1"=="" goto interactive_menu
set "R4OS_MODE=%~1"

if /i "%R4OS_MODE%"=="-help" goto usage_ok
if /i "%R4OS_MODE%"=="--help" goto usage_ok
if /i "%R4OS_MODE%"=="/?" goto usage_ok
if /i "%R4OS_MODE%"=="-central" goto mode_central
if /i "%R4OS_MODE%"=="-kernel" goto mode_kernel
if /i "%R4OS_MODE%"=="-modules" goto mode_modules
if /i "%R4OS_MODE%"=="-apps" goto mode_modules
if /i "%R4OS_MODE%"=="-module" goto mode_module
if /i "%R4OS_MODE%"=="-app" goto mode_module
if /i "%R4OS_MODE%"=="-plan" goto mode_plan
if /i "%R4OS_MODE%"=="-image" goto mode_image
if /i "%R4OS_MODE%"=="-verify" goto mode_verify
if /i "%R4OS_MODE%"=="-qemu" goto mode_qemu
if /i "%R4OS_MODE%"=="-guionly" goto mode_qemu
if /i "%R4OS_MODE%"=="-headless" goto mode_testonly
if /i "%R4OS_MODE%"=="-test" goto mode_test
if /i "%R4OS_MODE%"=="-testimage" goto mode_testimage
if /i "%R4OS_MODE%"=="-testimageonly" goto mode_testimageonly
if /i "%R4OS_MODE%"=="-testonly" goto mode_testonly
if /i "%R4OS_MODE%"=="-benchmarkimage" goto mode_benchmarkimage
if /i "%R4OS_MODE%"=="-benchmark" goto mode_benchmark
if /i "%R4OS_MODE%"=="-all" goto mode_all
if /i "%R4OS_MODE%"=="-norun" goto mode_all
if /i "%R4OS_MODE%"=="-slim" goto mode_slim
if /i "%R4OS_MODE%"=="-gui" goto mode_gui
goto usage

:interactive_menu
set "R4OS_INTERACTIVE=1"
echo.
echo R4OS Workspace Build-Menue
echo ==========================
echo 1  Contract, SDK und Libraries bauen
echo 2  Kernel bauen
echo 3  Alle Apps, Dienste, Diagnosen, Treiber, Protokolle und Subsysteme bauen
echo 4  Bestimmtes Modul bauen
echo 5  Gesamtbuild und Full-Image erzeugen
echo 6  Vorhandenes Full-Image in QEMU mit GUI starten
echo 7  Gesamtbuild, Full-Image und QEMU GUI
echo 8  Full-Image ohne Neukompilieren neu erzeugen
echo 9  Vorhandenes Full-Image verifizieren
echo 10 Gesamtbuild und Slim-Image erzeugen
echo 11 Gesamtbuild, Test-Image und automatischer Headless-Test
echo 12 Gesamtbuild und Test-Image ohne QEMU
echo 13 Vorhandenes Test-Image headless testen
echo 14 Test-Image ohne Neukompilieren neu erzeugen
echo 15 Gesamtbuild und Benchmark-Image ohne Benchmarklauf
echo 0  Abbrechen
echo.
set /p "R4OS_MENU_CHOICE=Auswahl: "
if "%R4OS_MENU_CHOICE%"=="1" goto menu_central
if "%R4OS_MENU_CHOICE%"=="2" goto menu_kernel
if "%R4OS_MENU_CHOICE%"=="3" goto menu_modules
if "%R4OS_MENU_CHOICE%"=="4" goto menu_module
if "%R4OS_MENU_CHOICE%"=="5" goto menu_all
if "%R4OS_MENU_CHOICE%"=="6" goto menu_qemu
if "%R4OS_MENU_CHOICE%"=="7" goto menu_gui
if "%R4OS_MENU_CHOICE%"=="8" goto menu_image
if "%R4OS_MENU_CHOICE%"=="9" goto menu_verify
if "%R4OS_MENU_CHOICE%"=="10" goto menu_slim
if "%R4OS_MENU_CHOICE%"=="11" goto menu_test
if "%R4OS_MENU_CHOICE%"=="12" goto menu_testimage
if "%R4OS_MENU_CHOICE%"=="13" goto menu_testonly
if "%R4OS_MENU_CHOICE%"=="14" goto menu_testimageonly
if "%R4OS_MENU_CHOICE%"=="15" goto menu_benchmarkimage
if "%R4OS_MENU_CHOICE%"=="0" exit /b 0
echo FEHLER: Ungueltige Auswahl.
goto interactive_error

:menu_central
call :run central Full
goto interactive_result

:menu_kernel
call :run kernel Full
goto interactive_result

:menu_modules
call :run modules Full
goto interactive_result

:menu_module
set "R4OS_MODULE_SELECTOR="
set /p "R4OS_MODULE_SELECTOR=Modulname oder Rollenpfad, z.B. Clock oder Apps\Clock: "
if not defined R4OS_MODULE_SELECTOR (
    echo FEHLER: Kein Modul angegeben.
    goto interactive_error
)
call :run_module "%R4OS_MODULE_SELECTOR%"
goto interactive_result

:menu_all
call :run all Full
goto interactive_result

:menu_qemu
call :run qemu Full
goto interactive_result

:menu_gui
call :run gui Full
goto interactive_result

:menu_image
call :run image Full
goto interactive_result

:menu_verify
call :run verify Full
goto interactive_result

:menu_slim
call :run all Slim
goto interactive_result

:menu_test
call :run test Test
goto interactive_result

:menu_testimage
call :run all Test
goto interactive_result

:menu_testonly
call :run headless Test
goto interactive_result

:menu_testimageonly
call :run image Test
goto interactive_result

:menu_benchmarkimage
call :run all Benchmark
goto interactive_result

:mode_central
if not "%~2"=="" goto usage
call :run central Full
exit /b %ERRORLEVEL%

:mode_kernel
if not "%~2"=="" goto usage
call :run kernel Full
exit /b %ERRORLEVEL%

:mode_modules
if not "%~2"=="" goto usage
call :run modules Full
exit /b %ERRORLEVEL%

:mode_module
if "%~2"=="" goto usage
if not "%~3"=="" goto usage
call :run_module "%~2"
exit /b %ERRORLEVEL%

:mode_plan
call :profile_or_default "%~2"
if errorlevel 1 goto usage
if not "%~3"=="" goto usage
call :run plan "%R4OS_PROFILE%"
exit /b %ERRORLEVEL%

:mode_image
call :profile_or_default "%~2"
if errorlevel 1 goto usage
if not "%~3"=="" goto usage
call :run image "%R4OS_PROFILE%"
exit /b %ERRORLEVEL%

:mode_verify
call :profile_or_default "%~2"
if errorlevel 1 goto usage
if not "%~3"=="" goto usage
call :run verify "%R4OS_PROFILE%"
exit /b %ERRORLEVEL%

:mode_qemu
call :profile_or_default "%~2"
if errorlevel 1 goto usage
if not "%~3"=="" goto usage
call :run qemu "%R4OS_PROFILE%"
exit /b %ERRORLEVEL%

:mode_test
if not "%~2"=="" goto usage
call :run test Test
exit /b %ERRORLEVEL%

:mode_testimage
if not "%~2"=="" goto usage
call :run all Test
exit /b %ERRORLEVEL%

:mode_testimageonly
if not "%~2"=="" goto usage
call :run image Test
exit /b %ERRORLEVEL%

:mode_testonly
if not "%~2"=="" goto usage
call :run headless Test
exit /b %ERRORLEVEL%

:mode_benchmarkimage
if not "%~2"=="" goto usage
call :run all Benchmark
exit /b %ERRORLEVEL%

:mode_benchmark
if "%~2"=="" goto usage
if "%~3"=="" goto usage
if "%~4"=="" goto usage
if "%~5"=="" goto usage
if "%~6"=="" goto usage
if not "%~7"=="" goto usage
call :run_benchmark "%~2" "%~3" "%~4" "%~5" "%~6"
exit /b %ERRORLEVEL%

:mode_all
call :profile_or_default "%~2"
if errorlevel 1 goto usage
if not "%~3"=="" goto usage
call :run all "%R4OS_PROFILE%"
exit /b %ERRORLEVEL%

:mode_slim
if not "%~2"=="" goto usage
call :run all Slim
exit /b %ERRORLEVEL%

:mode_gui
if not "%~2"=="" goto usage
call :run gui Full
exit /b %ERRORLEVEL%

:profile_or_default
set "R4OS_PROFILE=%~1"
if not defined R4OS_PROFILE set "R4OS_PROFILE=Full"
if /i "%R4OS_PROFILE%"=="Slim" exit /b 0
if /i "%R4OS_PROFILE%"=="Full" exit /b 0
if /i "%R4OS_PROFILE%"=="Test" exit /b 0
if /i "%R4OS_PROFILE%"=="Benchmark" exit /b 0
exit /b 1

:run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%R4OS_BUILD_HELPER%" -Action "%~1" -Profile "%~2"
exit /b %ERRORLEVEL%

:run_module
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%R4OS_BUILD_HELPER%" -Action module -Profile Full -ModuleSelector "%~1"
exit /b %ERRORLEVEL%

:run_benchmark
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%R4OS_BUILD_HELPER%" -Action benchmark -Profile Benchmark -BenchmarkSuite "%~1" -BenchmarkWorkloadVersion "%~2" -BenchmarkCacheState "%~3" -BenchmarkRepetitions "%~4" -BenchmarkEnvironmentId "%~5"
exit /b %ERRORLEVEL%

:interactive_result
if errorlevel 1 goto interactive_error
echo.
pause
exit /b 0

:interactive_error
echo.
echo *** Workspace-Build fehlgeschlagen. ***
pause
exit /b 1

:usage
call :print_usage
exit /b 1

:usage_ok
call :print_usage
exit /b 0

:print_usage
echo Verwendung:
echo   Build.bat
echo   Build.bat -central
echo   Build.bat -kernel
echo   Build.bat -modules
echo   Build.bat -module NAME^|ROLLE\NAME
echo   Build.bat -plan [Slim^|Full^|Test^|Benchmark]
echo   Build.bat -image [Slim^|Full^|Test^|Benchmark]
echo   Build.bat -verify [Slim^|Full^|Test^|Benchmark]
echo   Build.bat -qemu [Slim^|Full^|Test^|Benchmark]
echo   Build.bat -test
echo   Build.bat -testimage
echo   Build.bat -testimageonly
echo   Build.bat -testonly
echo   Build.bat -benchmarkimage
echo   Build.bat -benchmark SUITE WORKLOAD_VERSION WARM^|COLD REPETITIONS ENVIRONMENT_ID
echo   Build.bat -all [Slim^|Full^|Test^|Benchmark]
echo   Build.bat -slim
echo   Build.bat -gui
echo.
echo -gui baut den gesamten Workspace, erzeugt das Full-Image und startet
echo danach QEMU mit sichtbarer Oberflaeche ueber das Distribution-Repository.
echo -qemu startet nur ein bereits vorhandenes Image. Der Build aktualisiert
echo keine Git-Repositories automatisch.
echo -test baut den gesamten Workspace, erzeugt das Test-Image und prueft es
echo headless. -testonly prueft nur ein vorhandenes Test-Image.
echo -benchmarkimage baut das Benchmark-Image, startet aber keinen Benchmark.
echo -benchmark startet nur auf explizite, vollstaendige Anforderung ein bereits
echo vorhandenes Benchmark-Image. Die feste Umgebungs-ID steht in Agents\Build.txt.
exit /b 0
