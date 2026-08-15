param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('central', 'kernel', 'modules', 'module', 'plan', 'image', 'verify', 'qemu', 'all', 'gui')]
    [string]$Action,

    [ValidateSet('Slim', 'Full', 'Test')]
    [string]$Profile = 'Full',

    [string]$ModuleSelector
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repositoriesRoot = Join-Path $workspaceRoot 'Repositories'
$artifactsRoot = Join-Path $workspaceRoot 'Artifacts'
$devKitRoot = Join-Path $workspaceRoot 'DevKit'
$contractRoot = Join-Path $repositoriesRoot 'Contract'
$sdkRoot = Join-Path $repositoriesRoot 'SDK'
$librariesRoot = Join-Path $repositoriesRoot 'Libraries'
$kernelRoot = Join-Path $repositoriesRoot 'Kernel'
$distributionRoot = Join-Path $repositoriesRoot 'Distribution'
$zigExe = Join-Path $devKitRoot 'Toolchains/Zig/zig.exe'
$moduleCatalogExe = Join-Path $sdkRoot 'zig-out/bin/module-catalog.exe'
$distributionInputRoot = Join-Path $artifactsRoot 'Distribution/Inputs'
$workspaceMapPath = Join-Path $distributionInputRoot 'WorkspaceModules.map'
$dryRun = $env:R4OS_BUILD_DRYRUN -eq '1'
$testImageIncludes = @(
    '/R4OS/SOFTWARE/TERMINAL/BEEP.R4X',
    '/R4OS/SOFTWARE/DESKTOP/NOTEPAD.R4X',
    '/R4OS/SOFTWARE/DESKTOP/FONTS.R4X',
    '/R4OS/SOFTWARE/DESKTOP/APPEARANCE.R4X',
    '/R4OS/SOFTWARE/INTERNET/KLICKIFAX.R4X',
    '/R4OS/PROTOCOLS/R4HTTP.R4P',
    '/R4OS/PROTOCOLS/R4HTML.R4P',
    '/R4OS/PROTOCOLS/R4CSS.R4P',
    '/R4OS/PROTOCOLS/R4JS.R4P',
    '/R4OS/SDK/Toolchains/C/bin/R4CC.R4X',
    '/SOFTWARE/R4CODE/R4PACK.R4X',
    '/SOFTWARE/R4CODE/R4BUILD.R4X',
    '/R4OS/SOFTWARE/TERMINAL/HELP.R4X',
    '/R4OS/SERVICES/EXSVC.R4X',
    '/R4OS/SERVICES/RDPSVC.R4X',
    '/R4OS/SOFTWARE/TERMINAL/REG.R4X',
    '/R4OS/SOFTWARE/TERMINAL/SYSINFO.R4X',
    '/R4OS/SOFTWARE/TERMINAL/BOOTINFO.R4X'
)

function Write-Section([string]$Text) {
    Write-Host ''
    Write-Host ('=== ' + $Text + ' ===')
}

function Assert-File([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ($Label + ' fehlt: ' + $Path)
    }
}

function Assert-Directory([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw ($Label + ' fehlt: ' + $Path)
    }
}

function Invoke-External([string]$Path, [string[]]$Arguments, [string]$WorkingDirectory) {
    $rendered = @($Path) + $Arguments
    if ($dryRun) {
        Write-Host ('[DRY-RUN] ' + ($rendered -join ' '))
        return
    }
    Push-Location -LiteralPath $WorkingDirectory
    try {
        & $Path @Arguments
        $exitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    if ($exitCode -ne 0) {
        throw ('Befehl fehlgeschlagen, Exitcode ' + $exitCode + ': ' + $Path)
    }
}

function Get-GitDescription([string]$Root, [string]$Name) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
        Write-Host ($Name + ': kein Git-Checkout')
        return
    }
    $head = (& git -C $Root rev-parse --short=12 HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw ($Name + ': Git-Stand nicht lesbar') }
    $branch = (& git -C $Root rev-parse --abbrev-ref HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw ($Name + ': Git-Branch nicht lesbar') }
    $dirty = @(& git -C $Root status --porcelain=v1).Count -ne 0
    Write-Host ($Name + ': ' + $head + ' (' + $branch + $(if ($dirty) { ', geaendert' } else { ', sauber' }) + ')')
}

function Show-WorkspaceState {
    Write-Section 'Verwendete Workspace-Staende'
    Get-GitDescription $contractRoot 'Contract'
    Get-GitDescription $sdkRoot 'SDK'
    Get-GitDescription $librariesRoot 'Libraries'
    Get-GitDescription $kernelRoot 'Kernel'
    Get-GitDescription $distributionRoot 'Distribution'
}

function Get-RepositoryManifests([string]$GitRoot, [string]$ScopeRoot = $GitRoot) {
    if (-not (Test-Path -LiteralPath (Join-Path $GitRoot '.git'))) {
        throw ('Git-Checkout fuer Manifestermittlung fehlt: ' + $GitRoot)
    }
    $relativePaths = @(& git -C $GitRoot ls-files --cached --others --exclude-standard -- '*.R4MF')
    if ($LASTEXITCODE -ne 0) { throw ('Manifestliste nicht lesbar: ' + $GitRoot) }
    $scope = [IO.Path]::GetFullPath($ScopeRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $scopePrefix = $scope + [IO.Path]::DirectorySeparatorChar
    $result = foreach ($relativePath in $relativePaths) {
        $fullPath = [IO.Path]::GetFullPath((Join-Path $GitRoot $relativePath))
        if ($fullPath.Equals($scope, [StringComparison]::OrdinalIgnoreCase) -or
            $fullPath.StartsWith($scopePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $fullPath
        }
    }
    return @($result | Sort-Object)
}

function Get-Setting([string]$Path, [string]$Name) {
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) { continue }
        $separator = $trimmed.IndexOf('=')
        if ($separator -le 0) { continue }
        if ($trimmed.Substring(0, $separator).Trim().Equals($Name, [StringComparison]::OrdinalIgnoreCase)) {
            return $trimmed.Substring($separator + 1).Trim()
        }
    }
    throw ($Name + ' fehlt in ' + $Path)
}

function Resolve-SettingPath([string]$BasePath, [string]$Value) {
    if ([IO.Path]::IsPathRooted($Value)) {
        return [IO.Path]::GetFullPath($Value)
    }
    return [IO.Path]::GetFullPath((Join-Path $BasePath $Value))
}

function Get-ManifestValue([string]$ManifestPath, [string]$Name) {
    foreach ($line in [IO.File]::ReadAllLines($ManifestPath)) {
        $separator = $line.IndexOf('=')
        if ($separator -le 0) { continue }
        if (-not $line.Substring(0, $separator).Trim().Equals($Name, [StringComparison]::OrdinalIgnoreCase)) { continue }
        return $line.Substring($separator + 1).Trim()
    }
    throw ($Name + ' fehlt in ' + $ManifestPath)
}

function Get-ModuleRepositories {
    $result = [Collections.Generic.List[object]]::new()
    foreach ($role in @('Apps', 'Services', 'Diagnostics', 'Drivers', 'Protocols')) {
        $roleRoot = Join-Path $repositoriesRoot $role
        Assert-Directory $roleRoot ('Repositoryrolle ' + $role)
        foreach ($directory in Get-ChildItem -LiteralPath $roleRoot -Directory | Sort-Object Name) {
            $manifest = Join-Path $directory.FullName 'module.R4MF'
            $build = Join-Path $directory.FullName 'Build.bat'
            $settings = Join-Path $directory.FullName 'Settings.R4S'
            if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { continue }
            Assert-File $build ('Buildstarter fuer ' + $role + '/' + $directory.Name)
            Assert-File $settings ('Settings fuer ' + $role + '/' + $directory.Name)
            $result.Add([pscustomobject]@{
                Role = $role
                Name = $directory.Name
                ManifestName = Get-ManifestValue $manifest 'NAME'
                ManifestKind = Get-ManifestValue $manifest 'KIND'
                Root = $directory.FullName
                Manifest = $manifest
                Build = $build
                Settings = $settings
            })
        }
    }
    return @($result)
}

function Resolve-Module([string]$Selector) {
    if ([string]::IsNullOrWhiteSpace($Selector)) { throw 'Ein Modulname oder Rollenpfad ist erforderlich.' }
    $normalized = $Selector.Replace([IO.Path]::AltDirectorySeparatorChar, [IO.Path]::DirectorySeparatorChar).Trim([IO.Path]::DirectorySeparatorChar)
    $modules = @(Get-ModuleRepositories)
    if ($normalized.Contains([IO.Path]::DirectorySeparatorChar)) {
        $parts = $normalized.Split([IO.Path]::DirectorySeparatorChar)
        if ($parts.Count -ne 2) { throw ('Ungueltiger Modulpfad: ' + $Selector) }
        $matches = @($modules | Where-Object {
            $_.Role.Equals($parts[0], [StringComparison]::OrdinalIgnoreCase) -and
            $_.Name.Equals($parts[1], [StringComparison]::OrdinalIgnoreCase)
        })
    } else {
        $matches = @($modules | Where-Object {
            $_.Name.Equals($normalized, [StringComparison]::OrdinalIgnoreCase) -or
            $_.ManifestName.Equals($normalized, [StringComparison]::OrdinalIgnoreCase)
        })
    }
    if ($matches.Count -eq 0) { throw ('Modul nicht gefunden: ' + $Selector) }
    if ($matches.Count -gt 1) {
        $candidates = ($matches | ForEach-Object { $_.Role + '/' + $_.Name }) -join ', '
        throw ('Modulname ist mehrdeutig: ' + $Selector + '. Kandidaten: ' + $candidates)
    }
    return $matches[0]
}

function Build-Central {
    Write-Section 'Contract'
    Assert-File $zigExe 'Zig'
    Assert-File (Join-Path $contractRoot 'build.zig') 'Contract-Build'
    Invoke-External $zigExe @('build') $contractRoot

    Write-Section 'SDK'
    Invoke-External (Join-Path $sdkRoot 'Build.bat') @() $sdkRoot

    Write-Section 'Libraries'
    Invoke-External (Join-Path $librariesRoot 'Build.bat') @() $librariesRoot
}

function Build-Kernel {
    Write-Section 'Kernel'
    Invoke-External (Join-Path $kernelRoot 'Build.bat') @() $kernelRoot
}

function Build-OneModule($Module, [int]$Index, [int]$Count) {
    Write-Host ('[' + $Index + '/' + $Count + '] ' + $Module.Role + '/' + $Module.Name)
    Invoke-External $Module.Build @() $Module.Root
}

function Build-AllModules {
    $modules = @(Get-ModuleRepositories)
    Write-Section ('Module (' + $modules.Count + ')')
    for ($index = 0; $index -lt $modules.Count; $index++) {
        Build-OneModule $modules[$index] ($index + 1) $modules.Count
    }
}

function Build-SelectedModule([string]$Selector) {
    $module = Resolve-Module $Selector
    Write-Section ('Modul ' + $module.Role + '/' + $module.Name)
    Build-OneModule $module 1 1
}

function Get-ManifestArtifact([string]$ManifestPath, [string]$ArtifactRoot, [string]$Label) {
    Assert-Directory $ArtifactRoot ('Artefaktwurzel fuer ' + $Label)
    $manifestName = Get-ManifestValue $ManifestPath 'NAME'
    $manifestKind = Get-ManifestValue $ManifestPath 'KIND'
    if ($manifestKind -notin @('R4X', 'R4D', 'R4P', 'R4L')) {
        throw ('Unbekannte Modulart in ' + $ManifestPath + ': ' + $manifestKind)
    }
    $artifact = Join-Path $ArtifactRoot ($manifestName + '.' + $manifestKind)
    Assert-File $artifact ('Artefakt fuer ' + $Label + ' (' + $manifestName + '.' + $manifestKind + ')')
    return [IO.Path]::GetFullPath($artifact)
}

function Convert-ToPlanPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).Replace([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Write-Utf8NoBomLines([string]$Path, [string[]]$Lines) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    $encoding = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, (($Lines -join [Environment]::NewLine) + [Environment]::NewLine), $encoding)
}

function Ensure-ModuleCatalog {
    if (Test-Path -LiteralPath $moduleCatalogExe -PathType Leaf) { return }
    Write-Section 'SDK Hosttools fuer Imageplan'
    Invoke-External (Join-Path $sdkRoot 'Build.bat') @() $sdkRoot
    Assert-File $moduleCatalogExe 'ModuleCatalog'
}

function Write-WorkspaceMap {
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($module in (Get-ModuleRepositories)) {
        $artifactSetting = Get-Setting $module.Settings 'ARTIFACTS_ROOT'
        $artifactRoot = Resolve-SettingPath $module.Root $artifactSetting
        $manifests = @(Get-RepositoryManifests $module.Root)
        foreach ($manifest in $manifests) {
            $label = $module.Role + '/' + $module.Name
            $artifact = Get-ManifestArtifact $manifest $artifactRoot $label
            $lines.Add((Convert-ToPlanPath $manifest) + '|' + (Convert-ToPlanPath $artifact))
        }
    }

    $sdkArtifactRoot = Join-Path $sdkRoot 'zig-out'
    foreach ($manifest in (Get-RepositoryManifests $sdkRoot)) {
        $artifact = Get-ManifestArtifact $manifest $sdkArtifactRoot 'SDK'
        $lines.Add((Convert-ToPlanPath $manifest) + '|' + (Convert-ToPlanPath $artifact))
    }

    foreach ($libraryRoot in (Get-ChildItem -LiteralPath $librariesRoot -Directory | Sort-Object Name)) {
        if (-not (Test-Path -LiteralPath (Join-Path $libraryRoot.FullName 'module.R4MF') -PathType Leaf)) { continue }
        $libraryArtifactRoot = Join-Path $libraryRoot.FullName 'zig-out'
        foreach ($manifest in (Get-RepositoryManifests $librariesRoot $libraryRoot.FullName)) {
            $artifact = Get-ManifestArtifact $manifest $libraryArtifactRoot ('Libraries/' + $libraryRoot.Name)
            $lines.Add((Convert-ToPlanPath $manifest) + '|' + (Convert-ToPlanPath $artifact))
        }
    }
    Write-Utf8NoBomLines $workspaceMapPath @($lines)
    Write-Host ('Workspace-Map: ' + $lines.Count + ' Manifeste -> ' + $workspaceMapPath)
}

function Write-CommonPlan {
    $kernelArtifact = Join-Path $kernelRoot 'zig-out/bin/r4os.elf'
    $limineArtifact = Join-Path $devKitRoot 'Boot/Limine/limine-bios.sys'
    Assert-File $kernelArtifact 'Kernelartefakt'
    Assert-File $limineArtifact 'Limine BIOS-Datei'
    $commonPlan = Join-Path $distributionInputRoot 'Common.plan'
    Write-Utf8NoBomLines $commonPlan @(
        ((Convert-ToPlanPath $kernelArtifact) + ':/boot/r4os.elf'),
        ((Convert-ToPlanPath $limineArtifact) + ':/boot/limine-bios.sys')
    )
    Write-Host ('Common-Plan: 2 Eintraege -> ' + $commonPlan)
}

function New-ImagePlan([string]$SelectedProfile) {
    Write-Section ($SelectedProfile + '-Imageplan')
    Ensure-ModuleCatalog
    Write-WorkspaceMap
    Write-CommonPlan
    $componentPlan = Join-Path $distributionInputRoot ($SelectedProfile + '.plan')
    $arguments = [Collections.Generic.List[string]]::new()
    $arguments.Add('workspace-image-plan')
    $arguments.Add('--workspace-map')
    $arguments.Add($workspaceMapPath)
    $arguments.Add('--image-mode')
    $arguments.Add($SelectedProfile.ToLowerInvariant())
    if ($SelectedProfile.Equals('Test', [StringComparison]::OrdinalIgnoreCase)) {
        foreach ($target in $testImageIncludes) {
            $arguments.Add('--include-target')
            $arguments.Add($target)
        }
    }
    $arguments.Add('--output')
    $arguments.Add($componentPlan)
    Invoke-External $moduleCatalogExe @(
        $arguments.ToArray()
    ) $workspaceRoot
    Write-Host ('Komponentenplan: ' + $componentPlan)
}

function Invoke-Distribution([string]$DistributionAction, [string]$SelectedProfile) {
    Write-Section ('Distribution ' + $DistributionAction + ' ' + $SelectedProfile)
    Invoke-External (Join-Path $distributionRoot 'Build.bat') @($DistributionAction, $SelectedProfile) $distributionRoot
}

function Build-All([string]$SelectedProfile) {
    Build-Central
    Build-Kernel
    Build-AllModules
    New-ImagePlan $SelectedProfile
    Invoke-Distribution 'image' $SelectedProfile
}

Assert-Directory $repositoriesRoot 'Repositories'
Assert-Directory $devKitRoot 'DevKit'
Show-WorkspaceState

switch ($Action) {
    'central' { Build-Central }
    'kernel' { Build-Kernel }
    'modules' { Build-AllModules }
    'module' { Build-SelectedModule $ModuleSelector }
    'plan' { New-ImagePlan $Profile }
    'image' {
        New-ImagePlan $Profile
        Invoke-Distribution 'image' $Profile
    }
    'verify' { Invoke-Distribution 'verify' $Profile }
    'qemu' { Invoke-Distribution 'qemu' $Profile }
    'all' { Build-All $Profile }
    'gui' {
        Build-All 'Full'
        Invoke-Distribution 'qemu' 'Full'
    }
}

Write-Host ''
Write-Host 'R4OS Workspace-Build erfolgreich.'
