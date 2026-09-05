[CmdletBinding()]
param(
    [switch]$Push,
    [switch]$Pull,
    [switch]$Query,
    [switch]$Changed,
    [switch]$Workspace,
    [switch]$Project,
    [switch]$DevKit,
    [switch]$Docs,
    [switch]$Contract,
    [switch]$SDK,
    [switch]$Libraries,
    [switch]$Kernel,
    [switch]$Recovery,
    [switch]$Distribution,
    [switch]$Organization,
    [string]$App,
    [string]$Service,
    [string]$Diagnostic,
    [string]$Driver,
    [string]$Protocol,
    [string]$Subsystem,
    [Parameter(Position = 0)]
    [AllowEmptyString()]
    [string]$CommitMessage = '',
    [switch]$Preview
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$organizationName = 'R4OSDev'
$credentialFile = Join-Path $PSScriptRoot 'Credentials/Github.json'
$changedScript = Join-Path $PSScriptRoot 'GithubChanged.ps1'

function Invoke-GitCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $RepositoryRoot @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { [string]$_ })
    }
}

function Write-CommandOutput([object[]]$Output) {
    foreach ($line in $Output) {
        Write-Host ([string]$line)
    }
}

function Assert-GitSuccess([psobject]$Result, [string]$Message) {
    if ($Result.ExitCode -eq 0) { return }
    Write-CommandOutput $Result.Output
    throw $Message
}

function Invoke-WithEnvironment([hashtable]$Values, [scriptblock]$Operation) {
    $previous = @{}
    foreach ($name in $Values.Keys) {
        $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, [string]$Values[$name], 'Process')
    }
    try {
        return & $Operation
    }
    finally {
        foreach ($name in $Values.Keys) {
            [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
        }
    }
}

function New-CentralTarget([string]$Key) {
    switch ($Key) {
        'project' {
            $label = 'Project'; $root = $projectRoot; $name = 'r4os-project'
            $description = 'R4OS multi-repository project workspace.'; $allowInit = $false; $defaultCommit = 'Projektstand sichern'
        }
        'devkit' {
            $label = 'DevKit'; $root = Join-Path $projectRoot 'DevKit'; $name = 'r4os-devkit'
            $description = 'Cross-platform bootstrap and setup scripts for the R4OS development kit.'; $allowInit = $true; $defaultCommit = 'DevKit-Stand sichern'
        }
        'docs' {
            $label = 'Docs'; $root = Join-Path $projectRoot 'Docs'; $name = 'r4os-docs'
            $description = 'R4OS project documentation and inventories.'; $allowInit = $true; $defaultCommit = 'Dokumentationsstand sichern'
        }
        'contract' {
            $label = 'Contract'; $root = Join-Path $projectRoot 'Repositories/Contract'; $name = 'r4os-contract'
            $description = 'Canonical API and ABI contract for R4OS.'; $allowInit = $true; $defaultCommit = 'Contract-Stand sichern'
        }
        'sdk' {
            $label = 'SDK'; $root = Join-Path $projectRoot 'Repositories/SDK'; $name = 'r4os-sdk'
            $description = 'Host-neutral SDK and platform bindings for R4OS.'; $allowInit = $true; $defaultCommit = 'SDK-Stand sichern'
        }
        'libraries' {
            $label = 'Libraries'; $root = Join-Path $projectRoot 'Repositories/Libraries'; $name = 'r4os-libraries'
            $description = 'Official independent runtime libraries for R4OS.'; $allowInit = $true; $defaultCommit = 'Library-Stand sichern'
        }
        'kernel' {
            $label = 'Kernel'; $root = Join-Path $projectRoot 'Repositories/Kernel'; $name = 'r4os-kernel'
            $description = 'R4OS kernel, boot integration and kernel-owned tests.'; $allowInit = $true; $defaultCommit = 'Kernel-Stand sichern'
        }
        'recovery' {
            $label = 'Recovery'; $root = Join-Path $projectRoot 'Repositories/Recovery'; $name = 'r4os-recovery'
            $description = 'Independent R4OS recovery environment with a lightweight kernel and a pinned console runtime.'; $allowInit = $true; $defaultCommit = 'Recovery-Stand sichern'
        }
        'distribution' {
            $label = 'Distribution'; $root = Join-Path $projectRoot 'Repositories/Distribution'; $name = 'r4os-distribution'
            $description = 'R4OS image assembly, release configuration and distribution-owned host tools.'; $allowInit = $true; $defaultCommit = 'Distribution-Stand sichern'
        }
        'organization' {
            $label = 'Organisationsprofil'; $root = Join-Path $projectRoot 'Repositories/Organization'; $name = '.github'
            $description = 'Public R4OS organization profile and community metadata.'; $allowInit = $true; $defaultCommit = 'Organisationsprofil aktualisieren'
        }
        default { throw ('Unbekanntes Repositoryziel: ' + $Key) }
    }

    return [pscustomobject]@{
        Key = $Key
        Label = $label
        Root = [IO.Path]::GetFullPath($root)
        Name = $name
        Remote = 'https://github.com/' + $organizationName + '/' + $name + '.git'
        Description = $description
        Private = $false
        AllowInit = $allowInit
        Flag = '-' + $Key
        Component = ''
        DefaultCommitMessage = $defaultCommit
    }
}

function New-ComponentTarget([string]$Kind, [string]$ComponentName) {
    if ([string]::IsNullOrWhiteSpace($ComponentName)) {
        throw ('Fuer -' + $Kind + ' ist ein Komponentenname erforderlich.')
    }
    if ($ComponentName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9-]*$') {
        throw 'Der Komponentenname darf nur Buchstaben, Ziffern und Bindestriche enthalten.'
    }

    switch ($Kind) {
        'app' { $directory = 'Apps'; $label = 'Anwendung'; $description = 'Independent R4OS application' }
        'service' { $directory = 'Services'; $label = 'Dienst'; $description = 'Independent R4OS service' }
        'diagnostic' { $directory = 'Diagnostics'; $label = 'Diagnose'; $description = 'Independent R4OS diagnostic' }
        'driver' { $directory = 'Drivers'; $label = 'Treiber'; $description = 'Independent R4OS driver module' }
        'protocol' { $directory = 'Protocols'; $label = 'Protokoll'; $description = 'Independent R4OS protocol module' }
        'subsystem' { $directory = 'Subsystems'; $label = 'Subsystem'; $description = 'Independent R4OS subsystem host' }
        default { throw ('Unbekannte Komponentenrolle: ' + $Kind) }
    }

    $slug = $ComponentName.ToLowerInvariant()
    $repositoryName = 'r4os-' + $Kind + '-' + $slug
    return [pscustomobject]@{
        Key = $Kind + '-' + $slug
        Label = $label + ' ' + $ComponentName
        Root = [IO.Path]::GetFullPath((Join-Path $projectRoot ('Repositories/' + $directory + '/' + $ComponentName)))
        Name = $repositoryName
        Remote = 'https://github.com/' + $organizationName + '/' + $repositoryName + '.git'
        Description = $description + ' ' + $ComponentName + '.'
        Private = $false
        AllowInit = $true
        Flag = '-' + $Kind
        Component = $ComponentName
        DefaultCommitMessage = $ComponentName + '-Stand sichern'
    }
}

function Get-SelectedTarget {
    $targets = [Collections.Generic.List[object]]::new()
    foreach ($entry in @(
        [pscustomobject]@{ Selected = [bool]$Project; Key = 'project' },
        [pscustomobject]@{ Selected = [bool]$DevKit; Key = 'devkit' },
        [pscustomobject]@{ Selected = [bool]$Docs; Key = 'docs' },
        [pscustomobject]@{ Selected = [bool]$Contract; Key = 'contract' },
        [pscustomobject]@{ Selected = [bool]$SDK; Key = 'sdk' },
        [pscustomobject]@{ Selected = [bool]$Libraries; Key = 'libraries' },
        [pscustomobject]@{ Selected = [bool]$Kernel; Key = 'kernel' },
        [pscustomobject]@{ Selected = [bool]$Recovery; Key = 'recovery' },
        [pscustomobject]@{ Selected = [bool]$Distribution; Key = 'distribution' },
        [pscustomobject]@{ Selected = [bool]$Organization; Key = 'organization' }
    )) {
        if ($entry.Selected) { $targets.Add((New-CentralTarget $entry.Key)) }
    }

    foreach ($entry in @(
        [pscustomobject]@{ Value = $App; Kind = 'app' },
        [pscustomobject]@{ Value = $Service; Kind = 'service' },
        [pscustomobject]@{ Value = $Diagnostic; Kind = 'diagnostic' },
        [pscustomobject]@{ Value = $Driver; Kind = 'driver' },
        [pscustomobject]@{ Value = $Protocol; Kind = 'protocol' },
        [pscustomobject]@{ Value = $Subsystem; Kind = 'subsystem' }
    )) {
        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Value)) {
            $targets.Add((New-ComponentTarget $entry.Kind ([string]$entry.Value)))
        }
    }

    if ($targets.Count -ne 1) {
        throw 'Genau ein Repositoryziel ist erforderlich.'
    }
    return $targets[0]
}

function Get-WorkspaceTargets {
    $targets = [Collections.Generic.List[object]]::new()
    foreach ($key in @('contract', 'sdk', 'libraries', 'kernel')) {
        $targets.Add((New-CentralTarget $key))
    }
    foreach ($role in @(
        [pscustomobject]@{ Directory = 'Apps'; Kind = 'app' },
        [pscustomobject]@{ Directory = 'Services'; Kind = 'service' },
        [pscustomobject]@{ Directory = 'Diagnostics'; Kind = 'diagnostic' },
        [pscustomobject]@{ Directory = 'Drivers'; Kind = 'driver' },
        [pscustomobject]@{ Directory = 'Protocols'; Kind = 'protocol' },
        [pscustomobject]@{ Directory = 'Subsystems'; Kind = 'subsystem' }
    )) {
        $roleRoot = Join-Path $projectRoot ('Repositories/' + $role.Directory)
        if (-not (Test-Path -LiteralPath $roleRoot -PathType Container)) { continue }
        foreach ($directory in @(Get-ChildItem -LiteralPath $roleRoot -Directory | Sort-Object Name)) {
            $manifest = Join-Path $directory.FullName 'module.R4MF'
            $gitDirectory = Join-Path $directory.FullName '.git'
            if (-not (Test-Path -LiteralPath $manifest -PathType Leaf) -and
                -not (Test-Path -LiteralPath $gitDirectory)) {
                continue
            }
            $targets.Add((New-ComponentTarget $role.Kind $directory.Name))
        }
    }
    foreach ($key in @('recovery', 'distribution', 'docs', 'devkit', 'organization', 'project')) {
        $targets.Add((New-CentralTarget $key))
    }
    return @($targets)
}

function Read-Credentials {
    if (-not (Test-Path -LiteralPath $credentialFile -PathType Leaf)) {
        throw ('GitHub-Zugangsdaten fehlen: ' + $credentialFile + '. Bitte zuerst Tools/Setup ausfuehren.')
    }
    try {
        $value = Get-Content -Raw -LiteralPath $credentialFile | ConvertFrom-Json
    }
    catch {
        throw ('GitHub-Zugangsdaten sind kein gueltiges JSON: ' + $credentialFile)
    }
    $user = [string]$value.user
    $token = [string]$value.token
    if ([string]::IsNullOrWhiteSpace($user) -or [string]::IsNullOrWhiteSpace($token)) {
        throw 'GitHub-Benutzername oder Token fehlt.'
    }
    if ($user -eq 'DEIN_GITHUB_BENUTZERNAME' -or $token -eq 'github_pat_DEIN_TOKEN') {
        throw ('Bitte Benutzername und Token in ' + $credentialFile + ' eintragen.')
    }
    return [pscustomobject]@{ User = $user; Token = $token }
}

function Ensure-LocalRepository([psobject]$Target) {
    if (Test-Path -LiteralPath (Join-Path $Target.Root '.git')) { return }
    if (-not $Target.AllowInit) {
        throw ($Target.Root + ' ist kein Git-Repository.')
    }
    if (-not (Test-Path -LiteralPath $Target.Root)) {
        [void](New-Item -ItemType Directory -Path $Target.Root)
    }
    elseif (-not (Test-Path -LiteralPath $Target.Root -PathType Container)) {
        throw ($Target.Root + ' ist kein Verzeichnis.')
    }

    $result = Invoke-GitCommand $Target.Root @('init', '-b', 'main')
    Assert-GitSuccess $result ($Target.Label + ' konnte nicht als Git-Repository initialisiert werden.')
    Write-Host ($Target.Label + ' wurde lokal als Git-Repository initialisiert.')
}

function Assert-MainBranch([psobject]$Target) {
    $result = Invoke-GitCommand $Target.Root @('branch', '--show-current')
    Assert-GitSuccess $result ($Target.Label + ': Branch konnte nicht gelesen werden.')
    $branch = ($result.Output -join '').Trim()
    if ($branch -cne 'main') {
        throw ($Target.Label + ' muss auf dem Branch main stehen.')
    }
}

function Ensure-Origin([psobject]$Target) {
    $result = Invoke-GitCommand $Target.Root @('remote', 'get-url', 'origin')
    if ($result.ExitCode -ne 0) {
        $add = Invoke-GitCommand $Target.Root @('remote', 'add', 'origin', $Target.Remote)
        Assert-GitSuccess $add ($Target.Label + ': origin konnte nicht angelegt werden.')
        return
    }
    $current = ($result.Output -join '').Trim()
    if (-not $current.Equals($Target.Remote, [StringComparison]::OrdinalIgnoreCase)) {
        throw ('origin zeigt auf ' + $current + ' statt auf ' + $Target.Remote + '.')
    }
}

function Ensure-GitIdentity([psobject]$Target, [psobject]$Credentials) {
    $name = Invoke-GitCommand $Target.Root @('config', '--get', 'user.name')
    if ($name.ExitCode -ne 0) {
        Assert-GitSuccess (Invoke-GitCommand $Target.Root @('config', 'user.name', $Credentials.User)) 'Git-Benutzername konnte nicht gesetzt werden.'
    }
    $email = Invoke-GitCommand $Target.Root @('config', '--get', 'user.email')
    if ($email.ExitCode -ne 0) {
        Assert-GitSuccess (Invoke-GitCommand $Target.Root @('config', 'user.email', ($Credentials.User + '@users.noreply.github.com'))) 'Git-E-Mail konnte nicht gesetzt werden.'
    }
}

function Set-CanonicalShellModes([psobject]$Target) {
    if ($Target.Key -cne 'project') { return }
    foreach ($relativePath in @(
        'Tools/Setup.sh',
        'Tools/Github.sh',
        'Tools/Clean.sh',
        'Tools/Build.sh'
    )) {
        $fullPath = Join-Path $Target.Root $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
        $result = Invoke-GitCommand $Target.Root @('add', '--chmod=+x', '--', $relativePath)
        Assert-GitSuccess $result ('Ausfuehrbarkeitsbit konnte nicht gesetzt werden: ' + $relativePath)
    }
}

function Ensure-GitHubRepository([psobject]$Target, [psobject]$Credentials) {
    $headers = @{
        Accept = 'application/vnd.github+json'
        Authorization = 'Bearer ' + $Credentials.Token
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    $uri = 'https://api.github.com/repos/' + $organizationName + '/' + $Target.Name
    $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get -SkipHttpErrorCheck
    if ($response.StatusCode -eq 200) { return }
    if ($response.StatusCode -ne 404) {
        throw ('GitHub-Repository konnte nicht geprueft werden: HTTP ' + $response.StatusCode)
    }

    Write-Host ('GitHub-Repository ' + $organizationName + '/' + $Target.Name + ' wird erstellt.')
    $body = @{
        name = $Target.Name
        description = $Target.Description
        private = [bool]$Target.Private
    } | ConvertTo-Json -Compress
    $createUri = 'https://api.github.com/orgs/' + $organizationName + '/repos'
    $created = Invoke-WebRequest -Uri $createUri -Headers $headers -Method Post -ContentType 'application/json' -Body $body -SkipHttpErrorCheck
    if ($created.StatusCode -notin @(201, 202)) {
        throw ('GitHub-Repository konnte nicht erstellt werden: HTTP ' + $created.StatusCode + ' ' + $created.Content)
    }
}

function Invoke-Pull([psobject]$Target) {
    Ensure-LocalRepository $Target
    Assert-MainBranch $Target
    Ensure-Origin $Target

    $environment = @{
        GIT_ASKPASS = ''
        SSH_ASKPASS = ''
        GIT_TERMINAL_PROMPT = '0'
        GCM_INTERACTIVE = 'Never'
    }
    $result = Invoke-WithEnvironment $environment {
        Invoke-GitCommand $Target.Root @('-c', 'credential.helper=', 'pull', '--ff-only', 'origin', 'main')
    }
    Assert-GitSuccess $result ($Target.Label + ' konnte nicht von GitHub gepullt werden.')
    Write-CommandOutput $result.Output
    Write-Host ('ERFOLG: ' + $Target.Root + ' wurde von ' + $organizationName + '/' + $Target.Name + ' aktualisiert.')
}

function Invoke-Push([psobject]$Target) {
    $credentials = Read-Credentials
    Ensure-LocalRepository $Target
    Assert-MainBranch $Target
    Ensure-GitHubRepository $Target $credentials
    Ensure-Origin $Target

    $add = Invoke-GitCommand $Target.Root @('add', '-A')
    Assert-GitSuccess $add ($Target.Label + ': Dateien konnten nicht gestaged werden.')
    Set-CanonicalShellModes $Target

    $diff = Invoke-GitCommand $Target.Root @('diff', '--cached', '--quiet')
    if ($diff.ExitCode -eq 1) {
        Ensure-GitIdentity $Target $credentials
        $message = if ($CommitMessage -ne '') { $CommitMessage } else { $Target.DefaultCommitMessage }
        $commit = Invoke-GitCommand $Target.Root @('commit', '-m', $message)
        Assert-GitSuccess $commit ($Target.Label + ': Commit konnte nicht erstellt werden.')
        Write-CommandOutput $commit.Output
    }
    elseif ($diff.ExitCode -eq 0) {
        Write-Host ('Keine neuen Dateien in ' + $Target.Label + ' zum Committen.')
    }
    else {
        Assert-GitSuccess $diff ($Target.Label + ': Staged-Aenderungen konnten nicht geprueft werden.')
    }

    $basicValue = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($credentials.User + ':' + $credentials.Token))
    $environment = @{
        GIT_ASKPASS = ''
        SSH_ASKPASS = ''
        GIT_TERMINAL_PROMPT = '0'
        GCM_INTERACTIVE = 'Never'
        GIT_CONFIG_COUNT = '1'
        GIT_CONFIG_KEY_0 = 'http.extraHeader'
        GIT_CONFIG_VALUE_0 = 'Authorization: Basic ' + $basicValue
    }
    $pushResult = Invoke-WithEnvironment $environment {
        Invoke-GitCommand $Target.Root @('-c', 'credential.helper=', 'push', '-u', 'origin', 'main')
    }
    Assert-GitSuccess $pushResult ($Target.Label + ' konnte nicht nach GitHub gepusht werden.')
    Write-CommandOutput $pushResult.Output
    Write-Host ('ERFOLG: ' + $Target.Root + ' wurde nach ' + $organizationName + '/' + $Target.Name + ' gepusht.')
}

function Invoke-ChangedPush {
    if (-not (Test-Path -LiteralPath $changedScript -PathType Leaf)) {
        throw ('Sammel-Push-Skript fehlt: ' + $changedScript)
    }
    $arguments = [Collections.Generic.List[string]]::new()
    $arguments.Add('-NoLogo'); $arguments.Add('-NoProfile'); $arguments.Add('-File'); $arguments.Add($changedScript)
    if ($CommitMessage -ne '') { $arguments.Add('-CommitMessage'); $arguments.Add($CommitMessage) }
    if ($Preview) { $arguments.Add('-Preview') }
    & pwsh @($arguments.ToArray())
    if ($LASTEXITCODE -ne 0) { throw ('Sammel-Push fehlgeschlagen, Exitcode ' + $LASTEXITCODE + '.') }
}

function Show-Usage {
    Write-Host 'Verwendung:'
    Write-Host '  Github.bat|Github.sh -Push -Changed ["Commit-Beschreibung"]'
    Write-Host '  Github.bat|Github.sh -Pull -Project|-DevKit|-Docs|-Contract|-SDK|-Libraries|-Kernel|-Recovery|-Distribution|-Organization'
    Write-Host '  Github.bat|Github.sh -Push -Project|-DevKit|-Docs|-Contract|-SDK|-Libraries|-Kernel|-Recovery|-Distribution|-Organization ["Commit-Beschreibung"]'
    Write-Host '  Github.bat|Github.sh -Pull -App|-Service|-Diagnostic|-Driver|-Protocol|-Subsystem NAME'
    Write-Host '  Github.bat|Github.sh -Push -App|-Service|-Diagnostic|-Driver|-Protocol|-Subsystem NAME ["Commit-Beschreibung"]'
}

function Set-InteractiveSelection {
    Write-Host 'GitHub-Aktion auswaehlen:'
    Write-Host '  [1] Push'
    Write-Host '  [2] Pull'
    $actionChoice = Read-Host 'Auswahl'
    if ($actionChoice -eq '1') { $script:Push = $true }
    elseif ($actionChoice -eq '2') { $script:Pull = $true }
    else { throw 'Ungueltige Auswahl.' }

    if ($script:Push) {
        Write-Host 'Push-Modus auswaehlen:'
        Write-Host '  [1] Alle geaenderten Repositories'
        Write-Host '  [2] Einzelnes Repository'
        $modeChoice = Read-Host 'Auswahl'
        if ($modeChoice -eq '1') { $script:Changed = $true; return }
        if ($modeChoice -ne '2') { throw 'Ungueltige Auswahl.' }
    }

    Write-Host 'Repository: Project, DevKit, Docs, Contract, SDK, Libraries, Kernel, Recovery, Distribution, Organization, App, Service, Diagnostic, Driver, Protocol oder Subsystem'
    $targetChoice = (Read-Host 'Ziel').Trim().ToLowerInvariant()
    switch ($targetChoice) {
        'project' { $script:Project = $true }
        'devkit' { $script:DevKit = $true }
        'docs' { $script:Docs = $true }
        'contract' { $script:Contract = $true }
        'sdk' { $script:SDK = $true }
        'libraries' { $script:Libraries = $true }
        'kernel' { $script:Kernel = $true }
        'recovery' { $script:Recovery = $true }
        'distribution' { $script:Distribution = $true }
        'organization' { $script:Organization = $true }
        'app' { $script:App = Read-Host 'Komponentenname'; $PSBoundParameters['App'] = $script:App }
        'service' { $script:Service = Read-Host 'Komponentenname'; $PSBoundParameters['Service'] = $script:Service }
        'diagnostic' { $script:Diagnostic = Read-Host 'Komponentenname'; $PSBoundParameters['Diagnostic'] = $script:Diagnostic }
        'driver' { $script:Driver = Read-Host 'Komponentenname'; $PSBoundParameters['Driver'] = $script:Driver }
        'protocol' { $script:Protocol = Read-Host 'Komponentenname'; $PSBoundParameters['Protocol'] = $script:Protocol }
        'subsystem' { $script:Subsystem = Read-Host 'Komponentenname'; $PSBoundParameters['Subsystem'] = $script:Subsystem }
        default { throw 'Ungueltiges Repositoryziel.' }
    }
}

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git wurde nicht gefunden.'
    }

    $actionCount = @(@([bool]$Push, [bool]$Pull, [bool]$Query) | Where-Object { $_ }).Count
    if ($actionCount -eq 0) {
        Set-InteractiveSelection
        $actionCount = @(@([bool]$Push, [bool]$Pull, [bool]$Query) | Where-Object { $_ }).Count
    }
    if ($actionCount -ne 1) { throw 'Genau eine Aktion (-Push, -Pull oder -Query) ist erforderlich.' }

    if ($Changed) {
        if (-not $Push -or $Query -or $Pull) { throw '-Changed ist nur mit -Push erlaubt.' }
        Invoke-ChangedPush
        exit 0
    }

    if ($Workspace) {
        if (-not $Query) { throw '-Workspace ist nur mit -Query erlaubt.' }
        foreach ($workspaceTarget in @(Get-WorkspaceTargets)) {
            Write-Output (@(
                $workspaceTarget.Key,
                $workspaceTarget.Label,
                $workspaceTarget.Root,
                $workspaceTarget.Name,
                $workspaceTarget.Remote,
                $(if ($workspaceTarget.AllowInit) { '1' } else { '0' }),
                $workspaceTarget.Flag,
                $workspaceTarget.Component
            ) -join '|')
        }
        exit 0
    }

    $target = Get-SelectedTarget
    if ($Query) {
        Write-Output (@($target.Key, $target.Label, $target.Root, $target.Name, $target.Remote, $(if ($target.AllowInit) { '1' } else { '0' })) -join '|')
        exit 0
    }
    if ($Pull) { Invoke-Pull $target; exit 0 }
    Invoke-Push $target
    exit 0
}
catch {
    Write-Error ('GitHub-Aktion fehlgeschlagen: ' + $_.Exception.Message)
    Show-Usage
    exit 1
}
