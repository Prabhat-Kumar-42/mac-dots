#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
STATE_DIR="${TMPDIR:-/tmp}/sketchybar-rift-${UID:-$(id -u)}"
mkdir -p "$STATE_DIR" || exit 0

case "${1:-}" in
  workspaces)
    state_file="$STATE_DIR/workspaces.collapsed"
    if [ -f "$state_file" ]; then
      rm -f "$state_file"
      "$SKETCHYBAR" --set '/rift_ws_.*/' drawing=on
      "$SKETCHYBAR" --set workspaces_toggle label="Workspaces  ▾"
    else
      touch "$state_file"
      "$SKETCHYBAR" --set '/rift_ws_.*/' drawing=off
      active_name=$(cat "$STATE_DIR/workspaces.active" 2>/dev/null)
      [ -n "$active_name" ] || active_name=Workspaces
      "$SKETCHYBAR" --set workspaces_toggle label="$active_name  ▸"
    fi
    ;;
  system)
    state_file="$STATE_DIR/system.collapsed"
    if [ -f "$state_file" ]; then
      rm -f "$state_file"
      "$SKETCHYBAR" --set clock drawing=on --set volume drawing=on --set battery drawing=on
      "$SKETCHYBAR" --set system_toggle label="Status  ▾"
    else
      touch "$state_file"
      "$SKETCHYBAR" --set clock drawing=off --set volume drawing=off --set battery drawing=off
      "$SKETCHYBAR" --set system_toggle label="Status  ▸"
    fi
    ;;
esac
