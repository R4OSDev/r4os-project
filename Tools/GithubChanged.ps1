[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [AllowEmptyString()]
    [string]$CommitMessage = '',

    [switch]$Preview
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$githubScript = Join-Path $PSScriptRoot 'Github.ps1'
$pwshExecutable = (Get-Command pwsh -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $githubScript -PathType Leaf)) {
    Write-Host 'FEHLER: Tools/Github.ps1 fehlt.'
    exit 1
}

function Invoke-GithubScript {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = @(& $pwshExecutable -NoLogo -NoProfile -File $githubScript @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output | ForEach-Object { [string]$_ })
    }
}

function Invoke-GitRead {
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
    [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { [string]$_ })
    }
}

function Get-RepositoryState {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Target
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $exists = Test-Path -LiteralPath $Target.Root -PathType Container
    $isGit = $false
    $dirty = $false
    $worktreeText = 'nicht vorhanden'
    $branch = '-'
    $remoteText = 'nicht vorhanden'
    $actualRemote = ''
    $ahead = 0
    $needsPush = $false

    if (-not $exists) {
        return [pscustomobject]@{
            Target = $Target
            Exists = $false
            IsGit = $false
            Dirty = $false
            WorktreeText = $worktreeText
            Branch = $branch
            RemoteText = $remoteText
            ActualRemote = $actualRemote
            Ahead = 0
            NeedsPush = $false
            Error = ''
        }
    }

    $isGit = Test-Path -LiteralPath (Join-Path $Target.Root '.git')
    if (-not $isGit) {
        $hasContent = $null -ne (Get-ChildItem -LiteralPath $Target.Root -Force | Select-Object -First 1)
        if ($hasContent) {
            $dirty = $true
            $needsPush = $true
            $worktreeText = 'neu'
        }
        else {
            $worktreeText = 'leer'
        }
        $branch = 'main (geplant)'
        $remoteText = 'wird gesetzt'
        if ($hasContent -and -not $Target.AllowInit) {
            [void]$errors.Add('Repository darf nicht automatisch initialisiert werden')
        }

        return [pscustomobject]@{
            Target = $Target
            Exists = $true
            IsGit = $false
            Dirty = $dirty
            WorktreeText = $worktreeText
            Branch = $branch
            RemoteText = $remoteText
            ActualRemote = $actualRemote
            Ahead = 0
            NeedsPush = $needsPush
            Error = ($errors -join '; ')
        }
    }

    $branchResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('branch', '--show-current')
    if ($branchResult.ExitCode -ne 0) {
        [void]$errors.Add('Branch konnte nicht gelesen werden')
    }
    else {
        $branch = ($branchResult.Output -join '').Trim()
        if ($branch -eq '') {
            $symbolicResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('symbolic-ref', '--short', 'HEAD')
            if ($symbolicResult.ExitCode -eq 0) {
                $branch = ($symbolicResult.Output -join '').Trim()
            }
        }
        if ($branch -ne 'main') {
            [void]$errors.Add('Branch ist nicht main')
        }
    }

    $remoteResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('remote', 'get-url', 'origin')
    if ($remoteResult.ExitCode -ne 0) {
        $remoteText = 'fehlt (wird gesetzt)'
    }
    else {
        $actualRemote = ($remoteResult.Output -join '').Trim()
        if ([string]::Equals($actualRemote, $Target.Remote, [StringComparison]::OrdinalIgnoreCase)) {
            $remoteText = 'korrekt'
        }
        else {
            $remoteText = 'abweichend'
            [void]$errors.Add('origin stimmt nicht mit dem erwarteten R4OSDev-Remote ueberein')
        }
    }

    $statusResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('status', '--porcelain=v1', '--untracked-files=all')
    if ($statusResult.ExitCode -ne 0) {
        [void]$errors.Add('Arbeitsbaumstatus konnte nicht gelesen werden')
        $worktreeText = 'unbekannt'
    }
    else {
        $changeCount = @($statusResult.Output | Where-Object { $_ -ne '' }).Count
        if ($changeCount -gt 0) {
            $dirty = $true
            $worktreeText = 'geaendert (' + $changeCount + ')'
        }
        else {
            $worktreeText = 'sauber'
        }
    }

    $headResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('rev-parse', '--verify', '--quiet', 'HEAD')
    if ($headResult.ExitCode -eq 0) {
        $remoteHeadResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('rev-parse', '--verify', '--quiet', 'refs/remotes/origin/main')
        if ($remoteHeadResult.ExitCode -eq 0) {
            $aheadResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('rev-list', '--count', 'refs/remotes/origin/main..HEAD')
        }
        else {
            $aheadResult = Invoke-GitRead -RepositoryRoot $Target.Root -Arguments @('rev-list', '--count', 'HEAD')
        }

        if ($aheadResult.ExitCode -ne 0 -or $aheadResult.Output.Count -eq 0) {
            [void]$errors.Add('Unveroeffentlichte Commits konnten nicht ermittelt werden')
        }
        else {
            $parsedAhead = 0
            if (-not [int]::TryParse(($aheadResult.Output -join '').Trim(), [ref]$parsedAhead)) {
                [void]$errors.Add('Ungueltige Commitanzahl')
            }
            else {
                $ahead = $parsedAhead
            }
        }
    }

    $needsPush = $dirty -or $ahead -gt 0
    [pscustomobject]@{
        Target = $Target
        Exists = $true
        IsGit = $true
        Dirty = $dirty
        WorktreeText = $worktreeText
        Branch = $branch
        RemoteText = $remoteText
        ActualRemote = $actualRemote
        Ahead = $ahead
        NeedsPush = $needsPush
        Error = ($errors -join '; ')
    }
}

function Write-RepositoryState {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$State
    )

    if ($State.Error -ne '') {
        $marker = 'FEHLER'
    }
    elseif ($State.NeedsPush) {
        $marker = 'PUSH'
    }
    elseif (-not $State.Exists) {
        $marker = 'FEHLT'
    }
    else {
        $marker = 'OK'
    }

    Write-Host ('[{0}] {1} | Pfad={2} | Arbeitsbaum={3} | Branch={4} | Remote={5} | voraus={6}' -f
        $marker,
        $State.Target.Label,
        $State.Target.Root,
        $State.WorktreeText,
        $State.Branch,
        $State.RemoteText,
        $State.Ahead)

    if ($State.RemoteText -eq 'abweichend') {
        Write-Host ('         origin:   ' + $State.ActualRemote)
        Write-Host ('         erwartet: ' + $State.Target.Remote)
    }
    if ($State.Error -ne '') {
        Write-Host ('         Grund: ' + $State.Error)
    }
}

function Invoke-RepositoryPush {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Target
    )

    $invokeArguments = New-Object System.Collections.Generic.List[string]
    [void]$invokeArguments.Add('-push')
    [void]$invokeArguments.Add($Target.Flag)
    if ($Target.Component -ne '') {
        [void]$invokeArguments.Add($Target.Component)
    }
    if ($CommitMessage -ne '') {
        [void]$invokeArguments.Add($CommitMessage)
    }

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $pushResult = Invoke-GithubScript -Arguments @($invokeArguments.ToArray())
        $pushOutput = $pushResult.Output
        $pushExitCode = $pushResult.ExitCode
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    foreach ($line in $pushOutput) {
        Write-Host ([string]$line)
    }
    return $pushExitCode
}

function Write-ResultList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Items
    )

    Write-Host ($Title + ' (' + $Items.Count + '):')
    if ($Items.Count -eq 0) {
        Write-Host '  - keine'
        return
    }
    foreach ($item in $Items) {
        Write-Host ('  - ' + [string]$item)
    }
}

try {
    $targets = New-Object System.Collections.Generic.List[object]
    $workspaceResult = Invoke-GithubScript -Arguments @('-Query', '-Workspace')
    if ($workspaceResult.ExitCode -ne 0) {
        throw 'Workspace-Repositoryzuordnung konnte nicht gelesen werden.'
    }
    foreach ($line in $workspaceResult.Output) {
        if (([regex]::Matches($line, '\|')).Count -ne 7) { continue }
        $parts = @($line -split '\|', 8)
        if ($parts.Count -ne 8) { continue }
        $targets.Add([pscustomobject]@{
            Key = $parts[0]
            Label = $parts[1]
            Root = $parts[2]
            Name = $parts[3]
            Remote = $parts[4]
            AllowInit = ($parts[5] -eq '1')
            Flag = $parts[6]
            Component = $parts[7]
        })
    }
    if ($targets.Count -eq 0) {
        throw 'Workspace-Repositoryzuordnung ist leer.'
    }

    $states = New-Object System.Collections.Generic.List[object]
    foreach ($target in $targets) {
        [void]$states.Add((Get-RepositoryState -Target $target))
    }

    Write-Host
    Write-Host '=== Sammel-Push: Vorpruefung ==='
    Write-Host 'Reihenfolge: Contract, SDK, Libraries, Kernel, Apps, Services, Diagnostics, Drivers, Protocols, Subsystems, Distribution, Docs, DevKit, Organisation, Project.'
    Write-Host 'Ausgeschlossen: Server sowie alle verschachtelten DevKit- und Third-Party-Repositories.'
    Write-Host
    foreach ($state in $states) {
        Write-RepositoryState -State $state
    }

    $preflightErrors = @($states | Where-Object { $_.Error -ne '' })
    $pushCandidates = @($states | Where-Object { $_.NeedsPush -and $_.Error -eq '' })
    $unchangedStates = @($states | Where-Object { -not $_.NeedsPush -and $_.Error -eq '' })

    Write-Host
    Write-Host ('Vorpruefung: erkannt=' + $states.Count + ', push=' + $pushCandidates.Count + ', unveraendert=' + $unchangedStates.Count + ', fehler=' + $preflightErrors.Count)

    if ($Preview) {
        Write-Host 'Vorschau beendet; es wurde nichts committed oder gepusht.'
        if ($preflightErrors.Count -gt 0) {
            exit 1
        }
        exit 0
    }

    $pushed = New-Object System.Collections.Generic.List[string]
    $skipped = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]

    foreach ($state in $unchangedStates) {
        [void]$skipped.Add($state.Target.Label)
    }
    foreach ($state in $preflightErrors) {
        [void]$failed.Add($state.Target.Label + ': ' + $state.Error)
    }

    foreach ($state in $pushCandidates) {
        Write-Host
        Write-Host ('=== Push: ' + $state.Target.Label + ' ===')
        $pushExit = Invoke-RepositoryPush -Target $state.Target
        if ($pushExit -eq 0) {
            [void]$pushed.Add($state.Target.Label)
        }
        else {
            [void]$failed.Add($state.Target.Label + ': Einzel-Push mit Exitcode ' + $pushExit + ' fehlgeschlagen')
        }
    }

    $postStates = New-Object System.Collections.Generic.List[object]
    foreach ($target in $targets) {
        [void]$postStates.Add((Get-RepositoryState -Target $target))
    }
    $remaining = @($postStates | Where-Object { $_.Error -ne '' -or $_.NeedsPush })

    Write-Host
    Write-Host '=== Sammel-Push: Abschluss ==='
    Write-ResultList -Title 'Gepusht' -Items @($pushed)
    Write-ResultList -Title 'Unveraendert uebersprungen' -Items @($skipped)
    Write-ResultList -Title 'Fehlgeschlagen' -Items @($failed)
    Write-Host ('Verbleibende pushbare oder fehlerhafte Repositories (' + $remaining.Count + '):')
    if ($remaining.Count -eq 0) {
        Write-Host '  - keine'
    }
    else {
        foreach ($state in $remaining) {
            $reason = $state.Error
            if ($reason -eq '') {
                $reason = $state.WorktreeText + ', voraus=' + $state.Ahead
            }
            Write-Host ('  - ' + $state.Target.Label + ': ' + $reason)
        }
    }

    if ($failed.Count -gt 0 -or $remaining.Count -gt 0) {
        exit 1
    }

    Write-Host 'ERFOLG: Alle erkannten Aenderungen wurden veroeffentlicht.'
    exit 0
}
catch {
    Write-Host ('FEHLER: Sammel-Push abgebrochen: ' + $_.Exception.Message)
    exit 1
}
