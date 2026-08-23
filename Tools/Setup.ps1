[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$credentialDirectory = Join-Path $PSScriptRoot 'Credentials'
$credentialFile = Join-Path $credentialDirectory 'Github.json'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Ensure-Directory([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            throw ($Path + ' existiert, ist aber kein Verzeichnis.')
        }
        return
    }

    [void](New-Item -ItemType Directory -Path $Path)
    Write-Host ('Angelegt: ' + $Path)
}

function Ensure-File([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw ($Path + ' existiert, ist aber keine regulaere Datei.')
        }
        return
    }

    [IO.File]::WriteAllBytes($Path, [byte[]]::new(0))
    Write-Host ('Angelegt: ' + $Path)
}

try {
    Ensure-File (Join-Path $projectRoot 'QuickNotes.txt')

    foreach ($relativePath in @(
        'Artifacts',
        'Artifacts/Distribution/Inputs',
        'Artifacts/Distribution/PrivateInjection',
        'Artifacts/Modules',
        'Docs',
        'DevKit',
        'Repositories',
        'Repositories/Apps',
        'Repositories/Services',
        'Repositories/Diagnostics',
        'Repositories/Drivers',
        'Repositories/Protocols',
        'Repositories/Subsystems'
    )) {
        Ensure-Directory (Join-Path $projectRoot $relativePath)
    }

    Ensure-Directory $credentialDirectory
    if (-not $IsWindows) {
        & chmod 700 -- $credentialDirectory
        if ($LASTEXITCODE -ne 0) {
            throw ('Die Dateirechte von ' + $credentialDirectory + ' konnten nicht gesetzt werden.')
        }
    }

    if (Test-Path -LiteralPath $credentialFile) {
        if (-not (Test-Path -LiteralPath $credentialFile -PathType Leaf)) {
            throw ($credentialFile + ' existiert, ist aber keine regulaere Datei.')
        }
    }
    else {
        $credentialTemplate = [ordered]@{
            user = 'DEIN_GITHUB_BENUTZERNAME'
            token = 'github_pat_DEIN_TOKEN'
        } | ConvertTo-Json
        [IO.File]::WriteAllText($credentialFile, ($credentialTemplate + [Environment]::NewLine), $utf8NoBom)
        Write-Host ('Angelegt: ' + $credentialFile)
        Write-Host 'Optional: Fuer Pushes Benutzername und Token in der Datei eintragen.'
    }
    if (-not $IsWindows) {
        & chmod 600 -- $credentialFile
        if ($LASTEXITCODE -ne 0) {
            throw ('Die Dateirechte von ' + $credentialFile + ' konnten nicht gesetzt werden.')
        }
    }

    Write-Host 'Oeffentliche GitHub-Pulls funktionieren ohne ausgefuellte Credentials.'
    Write-Host 'Setup abgeschlossen.'
    exit 0
}
catch {
    Write-Error ('Setup fehlgeschlagen: ' + $_.Exception.Message)
    exit 1
}
