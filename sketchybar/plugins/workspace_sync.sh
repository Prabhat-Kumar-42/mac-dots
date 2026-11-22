#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
RIFT_CLI=/opt/homebrew/bin/rift-cli
JQ=/usr/bin/jq
STATE_DIR="${TMPDIR:-/tmp}/sketchybar-rift-${UID:-$(id -u)}"
CATALOG_FILE="$STATE_DIR/workspaces.catalog"
ACTIVE_FILE="$STATE_DIR/workspaces.active"
COLLAPSED_FILE="$STATE_DIR/workspaces.collapsed"
mkdir -p "$STATE_DIR" || exit 0

EVENT_SPACE_ID="${RIFT_SPACE_ID:-}"
EVENT_DISPLAY_UUID="${RIFT_DISPLAY_UUID:-}"
if [ -n "${RIFT_EVENT_JSON:-}" ]; then
  EVENT_SPACE_ID=$(printf '%s' "$RIFT_EVENT_JSON" | "$JQ" -r '.space_id // empty' 2>/dev/null)
  EVENT_DISPLAY_UUID=$(printf '%s' "$RIFT_EVENT_JSON" | "$JQ" -r '.display_uuid // empty' 2>/dev/null)
fi

if [ -n "$EVENT_SPACE_ID" ]; then
  WORKSPACES=$("$RIFT_CLI" query workspaces --space-id "$EVENT_SPACE_ID" 2>/dev/null) || exit 0
elif [ -n "$EVENT_DISPLAY_UUID" ]; then
  WORKSPACES=$("$RIFT_CLI" query workspaces --display "$EVENT_DISPLAY_UUID" 2>/dev/null) || exit 0
else
  WORKSPACES=$("$RIFT_CLI" query workspaces 2>/dev/null) || exit 0
fi

printf '%s' "$WORKSPACES" | "$JQ" -e 'type == "array"' >/dev/null 2>&1 || exit 0
CATALOG=$(printf '%s' "$WORKSPACES" | "$JQ" -r 'sort_by(.index) | .[] | [.index, .name] | @tsv' 2>/dev/null) || exit 0
ROWS=$(printf '%s' "$WORKSPACES" | "$JQ" -r 'sort_by(.index) | .[] | [.index, .name, (.is_focused // false), (.window_count // 0)] | @tsv' 2>/dev/null) || exit 0
ACTIVE_NAME=$(printf '%s' "$WORKSPACES" | "$JQ" -er 'first(.[] | select(.is_focused == true) | .name)' 2>/dev/null) || ACTIVE_NAME=""

OLD_CATALOG=""
[ -r "$CATALOG_FILE" ] && OLD_CATALOG=$(cat "$CATALOG_FILE")
if [ "${1:-}" = "--force" ] || [ "$CATALOG" != "$OLD_CATALOG" ]; then
  "$SKETCHYBAR" --remove workspace_capsule >/dev/null 2>&1 || true
  "$SKETCHYBAR" --remove '/rift_ws_.*/' >/dev/null 2>&1 || true

  workspace_items=(workspaces_toggle)
  while IFS="$(printf '\t')" read -r index name focused window_count; do
    [ -n "$index" ] || continue
    item="rift_ws_${index}"
    if [ "$focused" = "true" ]; then
      fg=0xffe8eaf0
      font="Helvetica Neue:Medium:13.0"
    else
      fg=0xffa6adbb
      font="Helvetica Neue:Regular:13.0"
    fi
    drawing=on
    [ -f "$COLLAPSED_FILE" ] && drawing=off
    "$SKETCHYBAR" --add item "$item" left \
      --set "$item" label="$name" \
        icon="$window_count" \
        icon.drawing=on \
        icon.font="Helvetica Neue:Regular:11.0" \
        icon.color="$fg" \
        icon.padding_left=4 \
        icon.padding_right=0 \
        label.font="$font" \
        label.color="$fg" \
        background.drawing=off \
        padding_left=2 \
        padding_right=2 \
        drawing="$drawing" \
        click_script="$RIFT_CLI execute workspace switch $index"
    "$SKETCHYBAR" --move "$item" after "${workspace_items[${#workspace_items[@]}-1]}"
    workspace_items+=("$item")
  done <<< "$ROWS"

  "$SKETCHYBAR" --add bracket workspace_capsule "${workspace_items[@]}" \
    --set workspace_capsule \
      background.drawing=on \
      background.color=0xe6171a20 \
      background.height=30 \
      background.corner_radius=12 \
      background.border_width=1 \
      background.border_color=0x283e4658
  printf '%s\n' "$CATALOG" > "$CATALOG_FILE"
fi

if [ -n "$ACTIVE_NAME" ]; then
  printf '%s\n' "$ACTIVE_NAME" > "$ACTIVE_FILE"
  if [ -f "$COLLAPSED_FILE" ]; then
    TOGGLE_LABEL="$ACTIVE_NAME  ▸"
  else
    TOGGLE_LABEL="Workspaces  ▾"
  fi
  "$SKETCHYBAR" --set workspaces_toggle label="$TOGGLE_LABEL"
fi

# Refresh selected styling even when the workspace catalog itself is unchanged.
while IFS="$(printf '\t')" read -r index name focused window_count; do
  [ -n "$index" ] || continue
  item="rift_ws_${index}"
  if [ "$focused" = "true" ]; then
    "$SKETCHYBAR" --set "$item" icon="$window_count" background.drawing=off label.color=0xffe8eaf0 icon.color=0xffe8eaf0 label.font="Helvetica Neue:Medium:13.0"
  else
    "$SKETCHYBAR" --set "$item" icon="$window_count" background.drawing=off label.color=0xffa6adbb icon.color=0xffa6adbb label.font="Helvetica Neue:Regular:13.0"
  fi
done <<< "$ROWS"
