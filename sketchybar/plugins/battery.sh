#!/bin/sh

BATTERY_INFO=$(pmset -g batt 2>/dev/null) || exit 0
PERCENTAGE=$(printf '%s\n' "$BATTERY_INFO" | sed -nE 's/.* ([0-9]+)%.*/\1/p' | head -n 1)
[ -n "$PERCENTAGE" ] || exit 0

LABEL="Battery ${PERCENTAGE}%"
case "$BATTERY_INFO" in
  *"AC Power"*) LABEL="${LABEL} +" ;;
esac

sketchybar --set "$NAME" label="$LABEL"
