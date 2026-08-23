#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

install_powershell_debian() {
    if [ ! -r /etc/os-release ]; then
        echo 'FEHLER: /etc/os-release kann nicht gelesen werden.' >&2
        exit 1
    fi

    # Die Distributionskennung ist die kanonische Schnittstelle fuer Linux-Hosts.
    # shellcheck disable=SC1091
    . /etc/os-release

    if [ "${ID:-}" != 'debian' ]; then
        echo "FEHLER: Die automatische PowerShell-Installation unterstuetzt derzeit Debian, erkannt wurde '${ID:-unbekannt}'." >&2
        echo 'PowerShell 7 bitte distributionsspezifisch installieren und Setup.sh erneut starten.' >&2
        exit 1
    fi

    debian_version=${VERSION_ID:-}
    case "$debian_version" in
        ''|*[!0-9]*)
            echo "FEHLER: Nicht unterstuetzte Debian-Versionskennung '$debian_version'." >&2
            exit 1
            ;;
    esac

    if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
        echo 'FEHLER: Fuer die Debian-Installation werden apt-get und dpkg benoetigt.' >&2
        exit 1
    fi

    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
        echo 'FEHLER: Fuer die PowerShell-Installation werden root-Rechte oder sudo benoetigt.' >&2
        exit 1
    fi

    echo "PowerShell 7 fehlt. Microsoft-Paketquelle fuer Debian $debian_version wird eingerichtet ..."
    run_as_root apt-get update
    run_as_root apt-get install -y ca-certificates curl

    pwsh_setup_temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/r4os-pwsh.XXXXXX")
    pwsh_setup_package="$pwsh_setup_temp_dir/packages-microsoft-prod.deb"
    cleanup_pwsh_setup() {
        if [ -f "$pwsh_setup_package" ]; then
            rm -f -- "$pwsh_setup_package"
        fi
        if [ -d "$pwsh_setup_temp_dir" ]; then
            rmdir -- "$pwsh_setup_temp_dir" 2>/dev/null || true
        fi
    }
    trap cleanup_pwsh_setup 0
    trap 'exit 1' 1 2 15

    curl --fail --location --retry 3 \
        --output "$pwsh_setup_package" \
        "https://packages.microsoft.com/config/debian/$debian_version/packages-microsoft-prod.deb"
    run_as_root dpkg -i "$pwsh_setup_package"

    cleanup_pwsh_setup
    trap - 0 1 2 15

    run_as_root apt-get update
    run_as_root apt-get install -y powershell
}

if ! command -v pwsh >/dev/null 2>&1; then
    if [ "$(uname -s)" != 'Linux' ]; then
        echo 'FEHLER: Setup.sh kann PowerShell nur auf Linux automatisch installieren.' >&2
        exit 1
    fi
    install_powershell_debian
fi

if ! command -v pwsh >/dev/null 2>&1; then
    echo 'FEHLER: PowerShell 7 (pwsh) ist nach der Installation nicht verfuegbar.' >&2
    exit 1
fi

if ! pwsh -NoLogo -NoProfile -Command 'if ($PSVersionTable.PSVersion.Major -lt 7) { exit 1 }'; then
    echo 'FEHLER: Setup.sh benoetigt PowerShell 7 oder neuer.' >&2
    exit 1
fi

exec pwsh -NoLogo -NoProfile -File "$script_dir/Setup.ps1" "$@"
