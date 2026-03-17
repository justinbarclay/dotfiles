#!/usr/bin/env zsh

front_app=(
  label.font="ProggyClean CE Nerd Font Mono:Regular:18.0"
  icon.font="sketchybar-app-font:Regular:16.0"
  icon.background.drawing=on
  background.drawing=on
  background.border_width=1
  background.border_color=$ACCENT_COLOR
  background.corner_radius=5
  background.height=40
  background.y_offset=10
  background.padding_left=10
  background.padding_right=10
  display=active
  script="$PLUGIN_DIR/front_app.zsh"
  click_script="open -a 'Mission Control'"
)
sketchybar --add item front_app left         \
           --set front_app "${front_app[@]}" \
           --subscribe front_app front_app_switched
