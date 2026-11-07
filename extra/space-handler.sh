#!/usr/bin/env bash
# Forward a byond:// URL from the host browser to BYOND inside the wine prefix.
set -euo pipefail

self="$(readlink -f "$0")"
log_file="$(dirname "$self")/last-run.log"
old_umask="$(umask)"
umask 077
if ! : > "$log_file"; then
    echo "Error: cannot write log file $log_file" >&2
    exit 1
fi
exec 3>> "$log_file"
umask "$old_umask"
exec 2> >(tee -a "$log_file" >&2)

log() {
    printf '[%(%Y-%m-%d %H:%M:%S %z)T] %s\n' -1 "$*" >&3
}

trap 'status=$?; log "Script exited with status $status."' EXIT
log "Started: pid=$$, parent=$PPID, argument count=$#"
parent_pid=$PPID
for _ in {1..8}; do
    read -r pid next_pid process_name < <(ps -p "$parent_pid" -o pid=,ppid=,comm= 2>/dev/null) || break
    log "Caller: pid=$pid, parent=$next_pid, process=$process_name"
    [ "$next_pid" -gt 0 ] || break
    parent_pid=$next_pid
done

# --register: make this script the host's handler for byond links.
if [ "${1:-}" = "--register" ]; then
    log "Registering the URL handler."
    command -v xdg-mime >/dev/null || {
        echo "Error: xdg-mime not found; cannot register the handler." >&2
        exit 0
    }
    apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    mkdir -p "$apps"
    cat > "$apps/byond-url-handler.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=BYOND URL Handler
Exec="$self" %u
NoDisplay=true
Terminal=false
MimeType=x-scheme-handler/byond;
EOF
    command -v update-desktop-database >/dev/null && update-desktop-database "$apps" || true
    xdg-mime default byond-url-handler.desktop x-scheme-handler/byond
    echo "Registered $self as the byond url handler."
    log "URL handler registered."
    exit 0
fi
# TODO: add more runners/checks for umu and proton
url="${1:-}"
[ -n "$url" ] || { echo "usage: $0 <byond-url> | --register" >&2; exit 1; }
case "$url" in
    byond://*) log "Received a byond:// URL (contents omitted)." ;;
    *) log "Received a non-empty argument that is not a byond:// URL (contents omitted)." ;;
esac

export WINEPREFIX="${WINEPREFIX:-$(dirname "$self")}"
export WINEDEBUG="${WINEDEBUG:--all}"
log "Using Wine prefix: $WINEPREFIX"

in_prefix() {
    tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | grep -qxF "WINEPREFIX=$WINEPREFIX"
}

# Sets server_exe if the pager is running in this prefix.
find_pager() {
    server_exe=""
    local pid
    for byond_pid in $(pgrep -if 'byond\.exe'); do
        in_prefix "$byond_pid" || continue
        for pid in $(pgrep -x wineserver); do
            if in_prefix "$pid"; then server_exe="$(readlink -f "/proc/$pid/exe")"; return 0; fi
        done
    done
    return 1
}

# Lutris game ID: $LUTRIS_GAME_ID, then a "lutris-id" file next to this script
# (an install script can write it), then a lookup by prefix directory.
lutris_id() {
    local dir; dir="$(dirname "$(readlink -f "$0")")"
    if [ -n "${LUTRIS_GAME_ID:-}" ]; then
        log "Using Lutris game ID from the environment."
        echo "$LUTRIS_GAME_ID"
    elif [ -s "$dir/lutris-id" ]; then
        log "Using Lutris game ID from lutris-id."
        head -n1 "$dir/lutris-id"
    elif command -v sqlite3 >/dev/null; then
        log "Looking up the Lutris game ID by prefix."
        sqlite3 "$HOME/.local/share/lutris/pga.db" \
            "select id from games where directory='${WINEPREFIX//\'/\'\'}' limit 1"
    else
        log "No Lutris game ID source available."
    fi
}

if ! find_pager; then
    log "No running BYOND pager found in the prefix."
    id="$(lutris_id)"
    [ -n "$id" ] || { echo "BYOND is not running and no Lutris game ID found." >&2; exit 1; }
    log "Starting Lutris game ID $id and waiting for BYOND."
    LUTRIS_SKIP_INIT=1 setsid lutris "lutris:rungameid/$id" >/dev/null 2>&1 &
    for _ in $(seq 24); do
        sleep 5
        find_pager && break
    done
    [ -n "$server_exe" ] || { echo "Timed out waiting for BYOND to start." >&2; exit 1; }
    log "BYOND detected; waiting 10 seconds for startup."
    sleep 10
else
    log "Found a running BYOND pager in the prefix."
fi

# Use the wine build matching the running wineserver.
WINE="${WINE:-$(dirname "$server_exe")/wine}"

# 64-bit prefixes use "Program Files (x86)"; win32 prefixes use "Program Files".
location="Program Files (x86)"
[ -d "$WINEPREFIX/drive_c/$location/BYOND" ] || location="Program Files"

log "Handing URL to Wine: executable=$WINE, BYOND directory=$location, wineserver=$server_exe"
exec "$WINE" "C:\\$location\\BYOND\\bin\\byond.exe" -url "$url"
