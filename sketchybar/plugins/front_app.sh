#!/bin/sh

if [ "$SENDER" = "front_app_switched" ] && [ -n "${INFO:-}" ]; then
  sketchybar --set "$NAME" label="$INFO"
  exit 0
fi

# On startup, seed the label from Rift's currently focused managed window.
WORKSPACES=$(/opt/homebrew/bin/rift-cli query workspaces 2>/dev/null) || exit 0
APP_NAME=$(printf '%s' "$WORKSPACES" | /usr/bin/jq -er 'first(.[] | .windows[]? | select(.is_focused == true) | .app_name)' 2>/dev/null) || exit 0
[ -n "$APP_NAME" ] && sketchybar --set "$NAME" label="$APP_NAME"
