#!/bin/sh

if [ "$SENDER" = "volume_change" ] && [ -n "${INFO:-}" ]; then
  sketchybar --set "$NAME" label="Vol ${INFO}%"
fi
