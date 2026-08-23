Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
$pathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }

function Test-SamePath([string]$Left, [string]$Right) {
    return [IO.Path]::GetFullPath($Left).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    ).Equals(
        [IO.Path]::GetFullPath($Right).TrimEnd(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ),
        $pathComparison
    )
}

function Assert-ContainedPath([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $prefix = $projectRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, $pathComparison)) {
        throw ('Unsicheres Clean-Ziel ausserhalb des Projektworkspace: ' + $fullPath)
    }
    return $fullPath
}

function Get-PathItem([string]$Path) {
    return (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
}

function Test-IsLink([IO.FileSystemInfo]$Item) {
    if ($null -eq $Item) { return $false }
    if ($null -ne $Item.LinkType) { return $true }
    return ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
}

function Remove-SafeEntry([string]$Path) {
    $fullPath = Assert-ContainedPath $Path
    $item = Get-PathItem $fullPath
    if ($null -eq $item) { return }

    if (Test-IsLink $item) {
        Remove-Item -LiteralPath $fullPath -Force
    }
    elseif ($item.PSIsContainer) {
        foreach ($child in @(Get-ChildItem -LiteralPath $fullPath -Force)) {
            Remove-SafeEntry $child.FullName
        }
        Remove-Item -LiteralPath $fullPath -Force
    }
    else {
        Remove-Item -LiteralPath $fullPath -Force
    }

    if ($null -ne (Get-PathItem $fullPath)) {
        throw ('Eintrag konnte nicht entfernt werden: ' + $fullPath)
    }
}

function Assert-WorkspaceSafety {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.gitignore') -PathType Leaf)) {
        throw ('Projektmarker fehlt: ' + (Join-Path $projectRoot '.gitignore'))
    }
}

function Clear-Artifacts {
    Assert-WorkspaceSafety
    $target = [IO.Path]::GetFullPath((Join-Path $projectRoot 'Artifacts'))
    $parent = [IO.Path]::GetFullPath((Split-Path -Parent $target))
    if (-not (Test-SamePath $parent $projectRoot) -or -not (Test-SamePath $target (Join-Path $projectRoot 'Artifacts'))) {
        throw 'Das berechnete Artifacts-Ziel liegt nicht sicher im Projektworkspace.'
    }

    if (-not (Test-Path -LiteralPath $target)) {
        [void](New-Item -ItemType Directory -Path $target)
        Write-Host 'Artifacts war nicht vorhanden und wurde leer angelegt.'
        return
    }

    $targetItem = Get-PathItem $target
    if ($null -eq $targetItem -or -not $targetItem.PSIsContainer -or (Test-IsLink $targetItem)) {
        throw 'Artifacts selbst ist kein sicheres regulaeres Verzeichnis.'
    }

    Write-Host ('Bereinige: ' + $target)
    Write-Host ('Behalte: ' + (Join-Path $target 'Distribution'))
    foreach ($entry in @(Get-ChildItem -LiteralPath $target -Force)) {
        if ($entry.Name.Equals('Distribution', $pathComparison)) { continue }
        Remove-SafeEntry $entry.FullName
    }

    $remaining = @(Get-ChildItem -LiteralPath $target -Force | Where-Object {
        -not $_.Name.Equals('Distribution', $pathComparison)
    })
    if ($remaining.Count -ne 0) {
        throw ('Artifacts konnte nicht vollstaendig geleert werden: ' + (($remaining.Name) -join ', '))
    }
    Write-Host 'Artifacts wurde ausserhalb von Distribution vollstaendig geleert.'
}

function Assert-NoLinkedParent([string]$Path) {
    $current = [IO.Path]::GetFullPath((Split-Path -Parent $Path))
    while (-not (Test-SamePath $current $projectRoot)) {
        $item = Get-PathItem $current
        if ($null -eq $item -or -not $item.PSIsContainer -or (Test-IsLink $item)) {
            throw ('Unsichere Parent-Kette fuer Zig-Cache: ' + $Path)
        }
        $next = [IO.Path]::GetFullPath((Split-Path -Parent $current))
        if (Test-SamePath $next $current) {
            throw ('Projektwurzel wurde in der Parent-Kette nicht erreicht: ' + $Path)
        }
        $current = $next
    }
}

function Get-ZigCachesUnder([string]$Root) {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return @() }
    $rootItem = Get-PathItem $Root
    if (Test-IsLink $rootItem) { return @() }

    $result = [Collections.Generic.List[string]]::new()
    $pending = [Collections.Generic.Stack[string]]::new()
    $pending.Push([IO.Path]::GetFullPath($Root))
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($directory in @(Get-ChildItem -LiteralPath $current -Directory -Force)) {
            if (Test-IsLink $directory) { continue }
            if ($directory.Name -ceq '.zig-cache') {
                $result.Add($directory.FullName)
            }
            else {
                $pending.Push($directory.FullName)
            }
        }
    }
    return @($result)
}

function Remove-ZigCache([string]$Path, [switch]$ExplicitDevKitCache) {
    $fullPath = Assert-ContainedPath $Path
    $item = Get-PathItem $fullPath
    if ($null -eq $item) { return $false }

    $expectedExplicit = Join-Path $projectRoot 'DevKit/.Cache/Zig'
    if ($ExplicitDevKitCache) {
        if (-not (Test-SamePath $fullPath $expectedExplicit)) {
            throw ('Unsicheres explizites Zig-Cache-Ziel: ' + $fullPath)
        }
    }
    elseif ([IO.Path]::GetFileName($fullPath) -cne '.zig-cache') {
        throw ('Unsicheres Zig-Cache-Ziel: ' + $fullPath)
    }

    Assert-NoLinkedParent $fullPath
    Remove-SafeEntry $fullPath
    Write-Host ('Entfernt: ' + $fullPath)
    return $true
}

function Clear-ZigCaches {
    Assert-WorkspaceSafety
    $targets = [Collections.Generic.HashSet[string]]::new(
        $(if ($IsWindows) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal })
    )

    $rootCache = Join-Path $projectRoot '.zig-cache'
    if (Test-Path -LiteralPath $rootCache) { [void]$targets.Add([IO.Path]::GetFullPath($rootCache)) }

    $explicitCache = Join-Path $projectRoot 'DevKit/.Cache/Zig'
    if (Test-Path -LiteralPath $explicitCache) { [void]$targets.Add([IO.Path]::GetFullPath($explicitCache)) }

    foreach ($scanRoot in @(
        (Join-Path $projectRoot 'Repositories'),
        (Join-Path $projectRoot 'DevKit/SDK'),
        (Join-Path $projectRoot 'DevKit/HostTools')
    )) {
        foreach ($cache in @(Get-ZigCachesUnder $scanRoot)) { [void]$targets.Add($cache) }
    }

    $artifactsRoot = Join-Path $projectRoot 'Artifacts'
    if (Test-Path -LiteralPath $artifactsRoot -PathType Container) {
        $artifactsRootCache = Join-Path $artifactsRoot '.zig-cache'
        if (Test-Path -LiteralPath $artifactsRootCache) { [void]$targets.Add([IO.Path]::GetFullPath($artifactsRootCache)) }
        foreach ($entry in @(Get-ChildItem -LiteralPath $artifactsRoot -Directory -Force)) {
            if ($entry.Name.Equals('Distribution', $pathComparison) -or (Test-IsLink $entry)) { continue }
            foreach ($cache in @(Get-ZigCachesUnder $entry.FullName)) { [void]$targets.Add($cache) }
        }
    }

    $removed = 0
    foreach ($target in @($targets | Sort-Object { $_.Length } -Descending)) {
        if (Test-SamePath $target $explicitCache) {
            if (Remove-ZigCache $target -ExplicitDevKitCache) { $removed++ }
        }
        elseif (Remove-ZigCache $target) {
            $removed++
        }
    }
    Write-Host ('Zig-Caches entfernt: ' + $removed)
}

function Show-Usage {
    Write-Host 'Verwendung:'
    Write-Host '  Clean.bat|Clean.sh'
    Write-Host '  Clean.bat|Clean.sh -all'
    Write-Host '  Clean.bat|Clean.sh -artifacts'
    Write-Host '  Clean.bat|Clean.sh -zig'
    Write-Host '  Clean.bat|Clean.sh -help'
}

try {
    $arguments = @($args)
    if ($arguments.Count -gt 1) { throw 'Zu viele Argumente.' }
    $mode = if ($arguments.Count -eq 0) { '-all' } else { $arguments[0].ToLowerInvariant() }
    switch ($mode) {
        '-all' { Clear-Artifacts; Clear-ZigCaches }
        '-artifacts' { Clear-Artifacts }
        '-zig' { Clear-ZigCaches }
        '-zig-cache' { Clear-ZigCaches }
        '-help' { Show-Usage }
        '--help' { Show-Usage }
        '/?' { Show-Usage }
        default { throw ('Unbekannter Clean-Modus: ' + $mode) }
    }
    exit 0
}
catch {
    Write-Error ('Clean fehlgeschlagen: ' + $_.Exception.Message)
    Show-Usage
    exit 1
}
