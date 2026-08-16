# R4OS Project Workspace

This private repository defines the lightweight Windows workspace used to
coordinate the independent R4OS repositories.

    DevKit/        Installed SDK and host tools
    Repositories/  Independent R4OS source repositories
    Artifacts/     Local build and test outputs
    Tools/         Workspace setup, build, and GitHub management

## Setup

After a fresh clone, run `Tools/Setup.bat`. Fill in the generated local
credentials template, pull the DevKit with
`Tools/Github.bat -pull -devkit`, and run
`DevKit/Setup/Setup_Windows.bat`.
The setup also creates the ignored local files `QuickNotes.txt` and
`Roadmap.txt` when missing, without overwriting existing content.

Use `Tools/Build.bat` as the multi-repository Windows build entry point.
Run it without arguments for the interactive menu.

Use `Tools/Clean.bat` or `Tools/Clean.bat -artifacts` to remove all local
build and test outputs while keeping the empty `Artifacts` directory.

Push and pull operations are performed exclusively through
`Tools/Github.bat`. Source repositories, installed tools, artifacts, and
credentials are ignored and are not stored in this project repository.

## License

Original R4OS workspace material is licensed under Apache License 2.0. See
`LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`.
