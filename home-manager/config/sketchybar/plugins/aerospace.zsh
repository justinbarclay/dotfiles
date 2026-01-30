#!/usr/bin/env zsh

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.zsh

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.zsh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.color=$ACCENT_COLOR label.shadow.drawing=on icon.shadow.drawing=on background.border_width=5 icon.color=$BAR_COLOR label.color=$BAR_COLOR
# background.color=0x88FF00FF
else
  sketchybar --set $NAME background.color=0x44FFFFFF label.shadow.drawing=off icon.shadow.drawing=off background.border_width=0 icon.color=$WHITE label.color=$WHITE
fi

sid=$1
apps=$(aerospace list-windows --workspace "$sid" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

if [ "${apps}" != "" ]; then
  icon_strip=" "
  while read -r app; do
    icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.zsh "$app")"
  done <<<"${apps}"
else
  icon_strip=""
fi

sketchybar --set $NAME label="$icon_strip"
