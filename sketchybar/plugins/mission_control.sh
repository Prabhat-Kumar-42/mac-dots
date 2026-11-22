#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
RIFT_CLI=/opt/homebrew/bin/rift-cli
STATE_DIR="${TMPDIR:-/tmp}/sketchybar-rift-${UID:-$(id -u)}"
MISSION_CONTROL_STATE="$STATE_DIR/mission-control.active"
mkdir -p "$STATE_DIR" || exit 1

restore_bar() {
  rm -f "$MISSION_CONTROL_STATE"
  "$SKETCHYBAR" --bar hidden=off
}

case "${1:-}" in
  toggle)
    if [ -f "$MISSION_CONTROL_STATE" ]; then
      "$RIFT_CLI" execute mission-control dismiss
      restore_bar
      exit $?
    fi
    "$SKETCHYBAR" --bar hidden=on || exit 1
    : > "$MISSION_CONTROL_STATE" || {
      "$SKETCHYBAR" --bar hidden=off
      exit 1
    }
    if ! "$RIFT_CLI" execute mission-control show-all; then
      restore_bar
      exit 1
    fi
    ;;
  dismiss)
    "$RIFT_CLI" execute mission-control dismiss
    restore_bar
    ;;
  restore)
    restore_bar
    ;;
  *)
    exit 2
    ;;
esac
