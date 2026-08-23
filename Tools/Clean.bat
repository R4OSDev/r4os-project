@echo off
setlocal EnableExtensions DisableDelayedExpansion

where pwsh.exe >nul 2>&1
if errorlevel 1 (
    echo FEHLER: PowerShell 7 ^(pwsh.exe^) wurde nicht gefunden.
    endlocal & exit /b 1
)

pwsh.exe -NoLogo -NoProfile -File "%~dp0Clean.ps1" %*
set "R4OS_CLEAN_EXIT=%ERRORLEVEL%"
endlocal & exit /b %R4OS_CLEAN_EXIT%
