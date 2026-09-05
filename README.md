# R4OS Project Workspace

This public repository defines the lightweight workspace used to coordinate
the independent R4OS repositories.

    Agents/        Compact agent-facing project references
    DevKit/        Installed SDK and host tools
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

Public source checkouts do not require a GitHub account or API token. Pull Docs
and the DevKit on Windows with `Tools\Github.bat -Pull -Docs` and
`Tools\Github.bat -Pull -DevKit`, or on Linux with
`./Tools/Github.sh -Pull -Docs` and `./Tools/Github.sh -Pull -DevKit`.
Initialize the checked-out DevKit with `DevKit\Setup\Setup_Windows.bat` or
`./DevKit/Setup/Setup_Linux.sh`. Both launch its shared PowerShell setup; the
Linux launcher installs the pinned native toolchain and host tools.
The setup also creates the ignored local file `QuickNotes.txt` when missing,
without overwriting existing content.

The generated shared credentials file `Tools/Credentials/Github.json` is
optional for read-only setup and pulls. Fill it in only when pushing changes or
creating repositories in the R4OSDev organization.

Use `Tools/Build.bat` on Windows or `./Tools/Build.sh` on Linux as the
multi-repository build entry point. Linux image, verification, and QEMU actions
still require matching Linux support from the Distribution repository; the
Project launcher does not emulate unavailable owner functionality.

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
is [R4OSDev/r4os-recovery](https://github.com/R4OSDev/r4os-recovery). The initial
repository prepares the Recovery work planned for roadmap 0.76.X.

## License

Original R4OS workspace material is licensed under Apache License 2.0. See
`LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`.
