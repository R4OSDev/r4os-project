Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$buildHelper = Join-Path $PSScriptRoot 'BuildWorkspace.ps1'
$validProfiles = @('Slim', 'Full', 'Test', 'Benchmark')

function Get-Profile([string]$Value, [string]$Default = 'Full') {
    $profile = if ([string]::IsNullOrWhiteSpace($Value)) { $Default } else { $Value }
    $match = @($validProfiles | Where-Object { $_.Equals($profile, [StringComparison]::OrdinalIgnoreCase) })
    if ($match.Count -ne 1) { throw ('Ungueltiges Buildprofil: ' + $profile) }
    return $match[0]
}

function Invoke-WorkspaceBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action,

        [string]$Profile = 'Full',

        [hashtable]$Additional = @{}
    )

    if (-not (Test-Path -LiteralPath $buildHelper -PathType Leaf)) {
        throw ('Build-Helfer fehlt: ' + $buildHelper)
    }
    $parameters = @{ Action = $Action; Profile = $Profile }
    foreach ($entry in $Additional.GetEnumerator()) { $parameters[$entry.Key] = $entry.Value }
    & $buildHelper @parameters
}

function Show-Usage {
    Write-Host 'Verwendung:'
    Write-Host '  Build.bat|Build.sh'
    Write-Host '  Build.bat|Build.sh -central|-kernel|-modules'
    Write-Host '  Build.bat|Build.sh -module NAME|ROLLE/NAME'
    Write-Host '  Build.bat|Build.sh -plan|-image|-verify|-qemu [Slim|Full|Test|Benchmark]'
    Write-Host '  Build.bat|Build.sh -test|-testimage|-testimageonly|-testonly|-benchmarkimage'
    Write-Host '  Build.bat|Build.sh -benchmark SUITE VERSION WARM|COLD WIEDERHOLUNGEN UMGEBUNGS-ID'
    Write-Host '  Build.bat|Build.sh -all [Slim|Full|Test|Benchmark]'
    Write-Host '  Build.bat|Build.sh -slim|-gui'
}

function Get-InteractiveArguments {
    Write-Host 'R4OS Workspace Build-Menue'
    Write-Host '========================='
    Write-Host '1  Contract, SDK und Libraries bauen'
    Write-Host '2  Kernel bauen'
    Write-Host '3  Alle Module bauen'
    Write-Host '4  Bestimmtes Modul bauen'
    Write-Host '5  Gesamtbuild und Full-Image erzeugen'
    Write-Host '6  Vorhandenes Full-Image in QEMU starten'
    Write-Host '7  Gesamtbuild, Full-Image und QEMU'
    Write-Host '8  Full-Image ohne Neukompilieren neu erzeugen'
    Write-Host '9  Vorhandenes Full-Image verifizieren'
    Write-Host '10 Gesamtbuild und Slim-Image erzeugen'
    Write-Host '11 Gesamtbuild, Test-Image und Headless-Test'
    Write-Host '12 Gesamtbuild und Test-Image ohne QEMU'
    Write-Host '13 Vorhandenes Test-Image headless testen'
    Write-Host '14 Test-Image ohne Neukompilieren neu erzeugen'
    Write-Host '15 Gesamtbuild und Benchmark-Image erzeugen'
    Write-Host '0  Abbrechen'
    $choice = Read-Host 'Auswahl'
    switch ($choice) {
        '1' { return @('-central') }
        '2' { return @('-kernel') }
        '3' { return @('-modules') }
        '4' {
            $module = Read-Host 'Modulname oder Rollenpfad'
            if ([string]::IsNullOrWhiteSpace($module)) { throw 'Kein Modul angegeben.' }
            return @('-module', $module)
        }
        '5' { return @('-all', 'Full') }
        '6' { return @('-qemu', 'Full') }
        '7' { return @('-gui') }
        '8' { return @('-image', 'Full') }
        '9' { return @('-verify', 'Full') }
        '10' { return @('-slim') }
        '11' { return @('-test') }
        '12' { return @('-testimage') }
        '13' { return @('-testonly') }
        '14' { return @('-testimageonly') }
        '15' { return @('-benchmarkimage') }
        '0' { return @('-cancel') }
        default { throw 'Ungueltige Auswahl.' }
    }
}

try {
    $commandArguments = @($args)
    if ($commandArguments.Count -eq 0) { $commandArguments = @(Get-InteractiveArguments) }
    $mode = $commandArguments[0].ToLowerInvariant()

    switch ($mode) {
        '-cancel' { exit 0 }
        '-help' { Show-Usage; exit 0 }
        '--help' { Show-Usage; exit 0 }
        '/?' { Show-Usage; exit 0 }
        '-central' {
            if ($commandArguments.Count -ne 1) { throw '-central akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action central
        }
        '-kernel' {
            if ($commandArguments.Count -ne 1) { throw '-kernel akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action kernel
        }
        '-modules' {
            if ($commandArguments.Count -ne 1) { throw '-modules akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action modules
        }
        '-apps' {
            if ($commandArguments.Count -ne 1) { throw '-apps akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action modules
        }
        { $_ -in @('-module', '-app') } {
            if ($commandArguments.Count -ne 2) { throw ($mode + ' benoetigt genau einen Modulnamen.') }
            Invoke-WorkspaceBuild -Action module -Additional @{ ModuleSelector = $commandArguments[1] }
        }
        { $_ -in @('-plan', '-image', '-verify', '-qemu', '-guionly') } {
            if ($commandArguments.Count -gt 2) { throw ($mode + ' akzeptiert hoechstens ein Profil.') }
            $profile = Get-Profile $(if ($commandArguments.Count -eq 2) { $commandArguments[1] } else { '' })
            $action = if ($mode -eq '-guionly') { 'qemu' } else { $mode.TrimStart('-') }
            Invoke-WorkspaceBuild -Action $action -Profile $profile
        }
        '-test' {
            if ($commandArguments.Count -ne 1) { throw '-test akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action test -Profile Test
        }
        '-testimage' {
            if ($commandArguments.Count -ne 1) { throw '-testimage akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action all -Profile Test
        }
        '-testimageonly' {
            if ($commandArguments.Count -ne 1) { throw '-testimageonly akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action image -Profile Test
        }
        { $_ -in @('-testonly', '-headless') } {
            if ($commandArguments.Count -ne 1) { throw ($mode + ' akzeptiert keine weiteren Argumente.') }
            Invoke-WorkspaceBuild -Action headless -Profile Test
        }
        '-benchmarkimage' {
            if ($commandArguments.Count -ne 1) { throw '-benchmarkimage akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action all -Profile Benchmark
        }
        '-benchmark' {
            if ($commandArguments.Count -ne 6) { throw '-benchmark benoetigt SUITE, VERSION, CACHE, WIEDERHOLUNGEN und UMGEBUNGS-ID.' }
            $repetitions = 0
            if (-not [int]::TryParse($commandArguments[4], [ref]$repetitions) -or $repetitions -le 0) {
                throw 'WIEDERHOLUNGEN muss eine positive Ganzzahl sein.'
            }
            Invoke-WorkspaceBuild -Action benchmark -Profile Benchmark -Additional @{
                BenchmarkSuite = $commandArguments[1]
                BenchmarkWorkloadVersion = $commandArguments[2]
                BenchmarkCacheState = $commandArguments[3]
                BenchmarkRepetitions = $repetitions
                BenchmarkEnvironmentId = $commandArguments[5]
            }
        }
        { $_ -in @('-all', '-norun') } {
            if ($commandArguments.Count -gt 2) { throw ($mode + ' akzeptiert hoechstens ein Profil.') }
            $profile = Get-Profile $(if ($commandArguments.Count -eq 2) { $commandArguments[1] } else { '' })
            Invoke-WorkspaceBuild -Action all -Profile $profile
        }
        '-slim' {
            if ($commandArguments.Count -ne 1) { throw '-slim akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action all -Profile Slim
        }
        '-gui' {
            if ($commandArguments.Count -ne 1) { throw '-gui akzeptiert keine weiteren Argumente.' }
            Invoke-WorkspaceBuild -Action gui -Profile Full
        }
        default { throw ('Unbekannter Buildmodus: ' + $mode) }
    }
    exit 0
}
catch {
    Write-Error ('Build fehlgeschlagen: ' + $_.Exception.Message)
    Show-Usage
    exit 1
}
