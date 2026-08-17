# R4OS Project Workspace

This public repository defines the lightweight Windows workspace used to
coordinate the independent R4OS repositories.

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
    Tools\Setup.bat

Public source checkouts do not require a GitHub account or API token. Pull Docs
and the DevKit with `Tools\Github.bat -pull -docs` and
`Tools\Github.bat -pull -devkit`, then run
`DevKit\Setup\Setup_Windows.bat`.
The setup also creates the ignored local files `QuickNotes.txt` and
`Roadmap.txt` when missing, without overwriting existing content.

The generated credentials template is optional for read-only setup and pulls.
Fill it in only when pushing changes or creating repositories in the R4OSDev
organization.

Use `Tools/Build.bat` as the multi-repository Windows build entry point.
Run it without arguments for the interactive menu.

Use `Tools/Clean.bat` to empty every `Artifacts` subtree except the preserved
`Artifacts/Distribution` tree and to remove R4OS-local `.zig-cache`
directories outside that tree. Use `-artifacts` or `-zig` for only one of
those operations. The Zig cleanup also covers the dedicated DevKit cache.
Installed toolchains, system-global Zig caches, `zig-out` directories, and
all Distribution outputs and private injection files remain untouched.

Push and pull operations are performed exclusively through
`Tools/Github.bat`. Public pulls are anonymous and explicitly ignore local
Git credential helpers. The normal multi-repository completion command is
`Tools/Github.bat -push -changed "Commit description"`; pushes continue to
use the ignored local token file.
Documentation, source repositories, installed tools, artifacts, and
credentials are ignored and are not stored in this project repository.

Independent applications, services, diagnostics, drivers, protocols, and
subsystem hosts live below their matching `Repositories` role. Subsystem
repositories use `Repositories/Subsystems/<Project>` and the public
`r4os-subsystem-*` naming convention. Installed hosts and guest formats are
resolved in userland from the profile-specific `MODULES.JSON` inventory.

## License

Original R4OS workspace material is licensed under Apache License 2.0. See
`LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`.
