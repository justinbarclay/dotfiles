#!/usr/bin/env zsh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

get_icon() {
  case "$1" in
    [6-9][0-9]|100) echo "󰕾" ;;
    [3-5][0-9]) echo "󰖀" ;;
    [1-9]|[1-2][0-9]) echo "󰕿" ;;
    *) echo "󰖁" ;;
  esac
}

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
  ICON=$(get_icon "$VOLUME")
  sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"

elif [ "$SENDER" = "mouse.scrolled" ]; then
  CURRENT=$(osascript -e "output volume of (get volume settings)")
  if [ "$INFO" -gt 0 ]; then
    NEW_VOL=$(( CURRENT + 5 > 100 ? 100 : CURRENT + 5 ))
  else
    NEW_VOL=$(( CURRENT - 5 < 0 ? 0 : CURRENT - 5 ))
  fi
  osascript -e "set volume output volume $NEW_VOL"
fi
