Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
$pathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$preview = $false
$previewBytes = [long]0
$previewTargets = 0

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

function Get-LogicalSize([IO.FileSystemInfo]$Item) {
    if (Test-IsLink $Item) { return [long]0 }
    if (-not $Item.PSIsContainer) { return [long]$Item.Length }
    $size = [long]0
    $pending = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
    $pending.Push($Item)
    while ($pending.Count -gt 0) {
        foreach ($child in $pending.Pop().EnumerateFileSystemInfos()) {
            if (Test-IsLink $child) { continue }
            if ($child -is [IO.DirectoryInfo]) { $pending.Push($child) }
            else { $size += $child.Length }
        }
    }
    return $size
}

function Remove-SafeItem([IO.FileSystemInfo]$Item) {
    if (Test-IsLink $Item) {
        Remove-Item -LiteralPath $Item.FullName -Force
        return
    }
    if ($Item -is [IO.DirectoryInfo]) {
        foreach ($child in $Item.EnumerateFileSystemInfos()) {
            Remove-SafeItem $child
        }
    }
    if (($Item.Attributes -band [IO.FileAttributes]::ReadOnly) -ne 0) {
        $Item.Attributes = $Item.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
    }
    $Item.Delete()
}

function Remove-SafeEntry([string]$Path) {
    $fullPath = Assert-ContainedPath $Path
    $item = Get-PathItem $fullPath
    if ($null -eq $item) { return }

    if ($script:preview) {
        $size = Get-LogicalSize $item
        $script:previewBytes += $size
        $script:previewTargets++
        Write-Host ('VORSCHAU: {0:N2} MB  {1}' -f ($size / 1MB), $fullPath)
        return
    }

    # Enumerate real entries explicitly; links are unlinked, never followed.
    # Native file operations avoid several provider lookups per cached file.
    Remove-SafeItem $item

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
        if (-not $script:preview) { [void](New-Item -ItemType Directory -Path $target) }
        Write-Host 'Artifacts war nicht vorhanden; nichts zu bereinigen.'
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

    if ($script:preview) { return }

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
            throw ('Unsichere Parent-Kette fuer Clean-Ziel: ' + $Path)
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
    $pending = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
    $pending.Push($rootItem)
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($directory in $current.EnumerateDirectories()) {
            if (Test-IsLink $directory) { continue }
            # Package sources, outputs and VCS data are not cache owners.
            if ($directory.Name -in @('.git', '.hg', '.svn', 'zig-pkg', 'zig-out')) { continue }
            if ($directory.Name -ceq '.zig-cache') {
                $result.Add($directory.FullName)
            }
            else {
                $pending.Push($directory)
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
    if (-not $script:preview) { Write-Host ('Entfernt: ' + $fullPath) }
    return $true
}

function Clear-ZigCaches([switch]$IncludeTemp) {
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
        Write-Host ('Suche Zig-Caches: ' + $scanRoot)
        foreach ($cache in @(Get-ZigCachesUnder $scanRoot)) { [void]$targets.Add($cache) }
    }
    if ($IncludeTemp) {
        Write-Host ('Suche Zig-Caches: ' + (Join-Path $projectRoot 'Temp'))
        foreach ($cache in @(Get-ZigCachesUnder (Join-Path $projectRoot 'Temp'))) {
            [void]$targets.Add($cache)
        }
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
    $verb = if ($script:preview) { 'vorgesehen' } else { 'entfernt' }
    Write-Host ('Zig-Caches ' + $verb + ': ' + $removed)
}

function Clear-BuildCaches {
    Clear-ZigCaches -IncludeTemp
    foreach ($relative in @('Artifacts/Kernel/Rust', 'Artifacts/Kernel/RustOwners', 'Artifacts/Distribution/.Cache')) {
        $target = Assert-ContainedPath (Join-Path $projectRoot $relative)
        if ($null -eq (Get-PathItem $target)) { continue }
        Assert-NoLinkedParent $target
        Remove-SafeEntry $target
        if (-not $script:preview) { Write-Host ('Buildcache entfernt: ' + $target) }
    }
}

# Only explicitly selected generated payloads are removed from these mixed
# trees. Reports, logs, source/work archives and manifests are never targets.
function Clear-PayloadFiles([string]$Root, [string[]]$Extensions) {
    $rootItem = Get-PathItem (Assert-ContainedPath $Root)
    if ($null -eq $rootItem) { return }
    Assert-NoLinkedParent $Root
    if (-not $rootItem.PSIsContainer -or (Test-IsLink $rootItem)) {
        throw ('Payloadwurzel ist kein regulaeres Verzeichnis: ' + $Root)
    }
    $pending = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
    $pending.Push($rootItem)
    $count = 0
    while ($pending.Count -gt 0) {
        foreach ($entry in $pending.Pop().EnumerateFileSystemInfos()) {
            if (Test-IsLink $entry) { continue }
            if ($entry -is [IO.DirectoryInfo]) {
                if ($entry.Name -in @('.git', '.hg', '.svn', '.zig-cache', 'zig-pkg',
                    'Source', 'Sources', 'Work', 'Reports', 'Legal')) { continue }
                $pending.Push($entry)
            }
            elseif ($entry.Extension.ToLowerInvariant() -in $Extensions) {
                Remove-SafeEntry $entry.FullName
                $count++
            }
        }
    }
    $verb = if ($script:preview) { 'vorgesehen' } else { 'entfernt' }
    Write-Host ('Payloads ' + $verb + ': ' + $count + ' unter ' + $Root)
}

function Clear-LocalPackages {
    Assert-WorkspaceSafety
    foreach ($relative in @('Temp', 'Artifacts/Distribution/Packages', 'Artifacts/Distribution/GraphicsPackages')) {
        Clear-PayloadFiles (Join-Path $projectRoot $relative) @('.r4u')
    }
}

function Clear-OldReleases {
    Assert-WorkspaceSafety
    $versionPath = Join-Path $projectRoot 'Repositories/Distribution/Injection/R4OS/CONFIG/VERSION.R4S'
    Assert-NoLinkedParent $versionPath
    $versionItem = Get-PathItem $versionPath
    if ($null -eq $versionItem -or $versionItem.PSIsContainer -or (Test-IsLink $versionItem)) {
        throw 'Releaseversionsdatei fehlt oder ist verlinkt; alte Releases bleiben erhalten.'
    }
    $releaseMatches = @([regex]::Matches([IO.File]::ReadAllText($versionPath), '(?m)^RELEASE_VERSION=(\d+\.\d+\.\d+)\s*$'))
    if ($releaseMatches.Count -ne 1) { throw 'Keine eindeutige RELEASE_VERSION; alte Releases bleiben erhalten.' }
    $currentVersion = [version]$releaseMatches[0].Groups[1].Value
    $root = Join-Path $projectRoot 'Artifacts/Distribution/Releases'
    $rootItem = Get-PathItem $root
    if ($null -eq $rootItem) { return }
    Assert-NoLinkedParent $root
    if (-not $rootItem.PSIsContainer -or (Test-IsLink $rootItem)) {
        throw 'Releasewurzel ist kein regulaeres Verzeichnis.'
    }
    Write-Host ('Behalte aktuelle/neuere Releases ab ' + $currentVersion)
    foreach ($directory in $rootItem.EnumerateDirectories()) {
        if ((Test-IsLink $directory) -or $directory.Name -notmatch '^\d+\.\d+\.\d+$') { continue }
        if ([version]$directory.Name -ge $currentVersion) { continue }
        Clear-PayloadFiles $directory.FullName @('.zip', '.r4u', '.img', '.qcow2', '.iso', '.elf', '.efi', '.pdb', '.exe', '.r4i')
    }
}

function Clear-TestArchives {
    Assert-WorkspaceSafety
    $diagnostics = Join-Path $projectRoot 'Artifacts/Distribution/Diagnostics'
    $standard = Join-Path $diagnostics 'SpectraStandard'
    $diagnosticsItem = Get-PathItem $diagnostics
    if ($null -ne $diagnosticsItem) {
        Assert-NoLinkedParent $diagnostics
        if (-not $diagnosticsItem.PSIsContainer -or (Test-IsLink $diagnosticsItem)) {
            throw 'Diagnosewurzel ist kein regulaeres Verzeichnis.'
        }
        foreach ($entry in $diagnosticsItem.EnumerateFileSystemInfos()) {
            if (-not (Test-SamePath $entry.FullName $standard)) {
                Remove-SafeEntry $entry.FullName
                continue
            }
            if ($entry -isnot [IO.DirectoryInfo] -or (Test-IsLink $entry)) {
                throw 'STANDARD-Archiv ist kein regulaeres Verzeichnis.'
            }
            # Immutable full JSON exports contain every comparison input.
            # Their generated source images, logs and work copies are disposable.
            foreach ($run in $entry.EnumerateFileSystemInfos()) {
                if ($run.Name -ceq 'References') {
                    if ($run -isnot [IO.DirectoryInfo] -or (Test-IsLink $run)) {
                        throw 'STANDARD-Referenzcache ist kein regulaeres Verzeichnis.'
                    }
                    continue
                }
                if ($run -isnot [IO.DirectoryInfo] -or (Test-IsLink $run)) {
                    Remove-SafeEntry $run.FullName
                    continue
                }
                foreach ($part in $run.EnumerateFileSystemInfos()) {
                    if ($part.Name -ceq 'run.json' -and $part -is [IO.FileInfo] -and -not (Test-IsLink $part)) { continue }
                    Remove-SafeEntry $part.FullName
                }
                if (-not $script:preview -and -not (Test-Path -LiteralPath (Join-Path $run.FullName 'run.json') -PathType Leaf)) {
                    Remove-SafeEntry $run.FullName
                }
            }
        }
    }
    foreach ($relative in @('Artifacts/Distribution/Technical', 'Artifacts/Distribution/Logs',
        'Artifacts/Distribution/Qualification', 'Artifacts/Distribution/ManualAcceptance',
        'Artifacts/Distribution/MediaAcceptance', 'Artifacts/Distribution/UsbAcceptance',
        'Artifacts/Distribution/Hardware', 'Repositories/Recovery/Artifacts/BootProbe')) {
        $target = Join-Path $projectRoot $relative
        if ($null -eq (Get-PathItem $target)) { continue }
        Assert-NoLinkedParent $target
        Remove-SafeEntry $target
    }
    foreach ($profile in @('Slim', 'Full', 'Test', 'Benchmark')) {
        $target = Join-Path $projectRoot ('Artifacts/Distribution/Profiles/' + $profile + '/Runs')
        if ($null -eq (Get-PathItem $target)) { continue }
        Assert-NoLinkedParent $target
        Remove-SafeEntry $target
    }
    $temp = Join-Path $projectRoot 'Temp'
    $tempItem = Get-PathItem $temp
    if ($null -ne $tempItem) {
        if (-not $tempItem.PSIsContainer -or (Test-IsLink $tempItem)) { throw 'Temp ist kein regulaeres Verzeichnis.' }
        foreach ($entry in $tempItem.EnumerateFileSystemInfos()) { Remove-SafeEntry $entry.FullName }
    }
    if (-not $script:preview) {
        Write-Host 'Alte Testausgaben und Temp geleert; STANDARD-JSON/Referenzen, Testquellen und Profilimages bleiben.'
    }
}

function Show-Usage {
    Write-Host 'Verwendung:'
    Write-Host '  Clean.bat|Clean.sh'
    Write-Host '  Clean.bat|Clean.sh -all'
    Write-Host '  Clean.bat|Clean.sh -artifacts'
    Write-Host '  Clean.bat|Clean.sh -zig'
    Write-Host '  Clean.bat|Clean.sh -caches'
    Write-Host '  Clean.bat|Clean.sh -packages'
    Write-Host '  Clean.bat|Clean.sh -releases'
    Write-Host '  Clean.bat|Clean.sh -obsolete'
    Write-Host '  Clean.bat|Clean.sh -tests'
    Write-Host '  Clean.bat|Clean.sh <Modus> -preview'
    Write-Host '  Clean.bat|Clean.sh -help'
    Write-Host ''
    Write-Host '-all (Standard): Artifacts ausser Distribution und bisherige lokale Zig-Caches.'
    Write-Host '-caches: zusaetzlich Temp-Zig-Caches, Rust-Builds und Distribution/.Cache.'
    Write-Host '-packages: lokale R4U-Pakete in Temp und Distribution-Paketordnern.'
    Write-Host '-releases: Payloads aelterer Releases; Notizen/Manifeste bleiben.'
    Write-Host '-obsolete: -packages und -releases zusammen.'
    Write-Host '-tests: alte Testumgebungen/-ergebnisse und ganz Temp; STANDARD-JSON/Referenzen bleiben.'
    Write-Host '-preview (auch -whatif): Ziele/Groessen anzeigen; nichts schreiben.'
    Write-Host 'Projektquellen, ExFiles und Fachberichte unter Docs bleiben erhalten.'
    Write-Host 'Aktuelle Profilimages, PrivateInjection, zig-out und installierte Toolchains bleiben.'
}

try {
    $arguments = @($args | Where-Object {
        if ($_ -in @('-preview', '--dry-run', '-whatif')) { $script:preview = $true; return $false }
        return $true
    })
    if ($arguments.Count -gt 1) { throw 'Zu viele Argumente.' }
    $mode = if ($arguments.Count -eq 0) { '-all' } else { $arguments[0].ToLowerInvariant() }
    switch ($mode) {
        '-all' { Clear-Artifacts; Clear-ZigCaches }
        '-artifacts' { Clear-Artifacts }
        '-zig' { Clear-ZigCaches }
        '-zig-cache' { Clear-ZigCaches }
        '-caches' { Clear-BuildCaches }
        '-packages' { Clear-LocalPackages }
        '-releases' { Clear-OldReleases }
        '-obsolete' { Clear-LocalPackages; Clear-OldReleases }
        '-tests' { Clear-TestArchives }
        '-help' { Show-Usage }
        '--help' { Show-Usage }
        '/?' { Show-Usage }
        default { throw ('Unbekannter Clean-Modus: ' + $mode) }
    }
    if ($script:preview) {
        Write-Host ('Vorschau: {0} Ziele, {1:N2} GB logische Dateigroesse.' -f $script:previewTargets, ($script:previewBytes / 1GB))
        Write-Host 'Sparse-Dateien/Hardlinks koennen weniger belegen; dies ist keine Zusage freien Plattenplatzes.'
    }
    exit 0
}
catch {
    [Console]::Error.WriteLine('Clean fehlgeschlagen: ' + $_.Exception.Message)
    Show-Usage
    exit 1
}
