# R4OS Project Workspace

This public repository defines the lightweight workspace used to coordinate
the independent R4OS repositories. The production kernel uses Rust and the
required x86_64 assembly. Applications, services, libraries, drivers, protocols
and the separate Recovery kernel retain their existing Zig builds.

    Agents/        Compact agent-facing project references
    DevKit/        Local tool installations; no parent remote repository
    Docs/          Cross-project documentation and inventories
    Repositories/  Independent R4OS source repositories
    Artifacts/     Local build and test outputs
    Tools/         Workspace setup, build, and GitHub management

## Setup

Clone the public workspace and initialize its local structure:

    git clone https://github.com/R4OSDev/r4os-project.git R4OS
    cd R4OS

Git is required on both hosts. PowerShell 7 (`pwsh`) must already be available
on Windows. Run:

    Tools\Setup.bat

On Debian Linux run:

    ./Tools/Setup.sh

If `pwsh` is missing, `Setup.sh` installs it from Microsoft's Debian package
repository before starting the shared `Setup.ps1`. This requires root or
`sudo` privileges and outbound access for APT and HTTPS.

The Batch and shell files are thin host launchers. Shared setup, GitHub, clean,
and workspace-build behavior is implemented once in PowerShell 7 using paths
derived from each script location.

Public source checkouts do not require a GitHub account or API token. On
Windows, pull `Docs` with `Tools\Github.bat -Pull -Docs`, then the SDK and
components with `Tools\Github.bat -Pull -SDK -Contract -Libraries`. On Linux,
use `./Tools/Github.sh -Pull -Docs` and
`./Tools/Github.sh -Pull -SDK -Contract -Libraries`.
Install the SDK-selected tools with
`Repositories\SDK\Tools\Setup.bat -InstallRoot DevKit` on Windows or
`./Repositories/SDK/Tools/Setup.sh -InstallRoot DevKit` on Linux.
The SDK alone defines build and tool profiles, Contract and system libraries
in `Profiles/Build.json`, `Profiles/Tools.json` and `Profiles/Components.json`.
Component checkouts must match that selection; applications may pin additional
libraries. DevKit remains a local installation location. Its retired parent
repository must not be pulled, pushed or recreated. See `Agents/Build.txt`
and `Docs/SDK/Profiles.txt` for the matched setup and build workflow.
The setup also creates the ignored local file `QuickNotes.txt` when missing,
without overwriting existing content.

The generated shared credentials file `Tools/Credentials/Github.json` is
optional for read-only setup and pulls. Fill it in only when pushing changes or
creating repositories in the R4OSDev organization.

Use `Tools/Build.bat` on Windows or `./Tools/Build.sh` on Linux as the
multi-repository build entry point. Image generation, verification, and QEMU
checks are provided by the Distribution repository on Windows and Linux,
using the selected host tools and the shared PowerShell orchestration.

Use `Tools/Clean.bat` or `./Tools/Clean.sh` to empty every `Artifacts` subtree
except the preserved `Artifacts/Distribution` tree and to remove R4OS-local
`.zig-cache` directories outside that tree. Use `-artifacts` or `-zig` for only
one of those operations. The Zig cleanup also covers the dedicated DevKit cache.
Installed toolchains, system-global Zig caches, `zig-out` directories, and
all Distribution outputs and private injection files remain untouched.

Push and pull operations are performed through `Tools/Github.bat` or
`./Tools/Github.sh`. Public pulls are anonymous and explicitly ignore local Git
credential helpers. The normal multi-repository completion command uses
`-Push -Changed "Commit description"`; pushes use the ignored shared JSON
credentials file.
Documentation, source repositories, installed tools, artifacts, and
credentials are ignored and are not stored in this project repository.

Independent applications, services, diagnostics, drivers, protocols, and
subsystem hosts live below their matching `Repositories` role. Subsystem
repositories use `Repositories/Subsystems/<Project>` and the public
`r4os-subsystem-*` naming convention. Installed hosts and guest formats are
resolved in userland from the profile-specific `MODULES.JSON` inventory.

The independent Recovery repository lives at `Repositories/Recovery` and is
managed with the `-Recovery` GitHub target. Use
`Tools\Github.bat -Pull -Recovery` on Windows or
`./Tools/Github.sh -Pull -Recovery` on Linux to check it out. Its public remote
is [R4OSDev/r4os-recovery](https://github.com/R4OSDev/r4os-recovery). It boots a separate RAM-resident repair environment and supports installation,
offline repair, updates and rollback. Its kernel/runtime pair and release
version remain independent of the normal R4OS release.

## License

Original R4OS workspace material is licensed under Apache License 2.0. See
`LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`.
