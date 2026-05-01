{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.darwin.sketchybar;

  # Import Themes
  themes = import ./sketchybar_themes.nix;
  colors = themes."${cfg.theme}";

  # Import Icon Map
  icon_map_cases = import ./sketchybar_icons.nix { inherit pkgs lib colors; };

  # Helper to write a plugin script
  mkPlugin = name: text: pkgs.writeShellScript "sketchybar-plugin-${name}" ''
    export PATH="${lib.makeBinPath [ pkgs.sketchybar pkgs.aerospace pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.bc ]}:/usr/bin:/usr/sbin:/bin:$PATH"
    ${text}
  '';

  # Dynamic Workspace Controller
  workspace_controller = mkPlugin "workspaces" ''
    icon_map() {
      ${icon_map_cases}
    }

    refresh_workspaces() {
      WORKSPACES=$(aerospace list-workspaces --all)
      FOCUSED=$(aerospace list-workspaces --focused)
      EXISTING=$(sketchybar --query bar | grep -o 'space\.[^", ]*' | cut -d. -f2 || true)

      for ws in $WORKSPACES; do
        if ! echo "$EXISTING" | grep -q "^$ws$"; then
          sketchybar --add item "space.$ws" left \
            --set "space.$ws" \
              icon="$ws" \
              icon.padding_left=12 \
              icon.padding_right=8 \
              label.padding_right=12 \
              background.drawing=on \
              background.border_width=1 \
              script="$0 update_workspace $ws" \
              click_script="aerospace workspace $ws" \
            --subscribe "space.$ws" aerospace_workspace_change
        fi
      done

      for ext in $EXISTING; do
        if ! echo "$WORKSPACES" | grep -q "^$ext$"; then
          sketchybar --remove "space.$ext"
        fi
      done

      ALL_WINDOWS=$(aerospace list-windows --all --format "%{workspace} %{app-name}")

      for ws in $WORKSPACES; do
        if [ "$ws" = "$FOCUSED" ]; then
          sketchybar --set "space.$ws" background.drawing=on \
                     --set "space.$ws" background.border_color=${colors.accent} \
                     --set "space.$ws" label.color=${colors.accent} \
                     --set "space.$ws" icon.color=${colors.accent}
        else
          sketchybar --set "space.$ws" background.drawing=on \
                     --set "space.$ws" background.border_color=${colors.border} \
                     --set "space.$ws" label.color=${colors.fg} \
                     --set "space.$ws" icon.color=${colors.fg}
        fi

        WS_APPS=$(echo "$ALL_WINDOWS" | grep "^$ws " | cut -d' ' -f2- | sort | uniq)
        ICON_STR=""
        while read -r app; do
          if [ -z "$app" ]; then continue; fi
          icon_map "$app"
          ICON_STR="$ICON_STR $icon_result"
        done <<< "$WS_APPS"
        sketchybar --set "space.$ws" label="$ICON_STR"
      done
    }

    if [ "$1" = "update_workspace" ]; then
      refresh_workspaces
    else
      refresh_workspaces
    fi
  '';

  # Front App Plugin
  front_app_plugin = mkPlugin "front_app" ''
    if [ "$SENDER" = "front_app_switched" ]; then
      sketchybar --set "$NAME" label="$INFO"
    fi
  '';

  # Clock Plugin
  clock_plugin = mkPlugin "clock" ''
    sketchybar --set "$NAME" label="$(date '+%a %d %b %H:%M')"
  '';

  # Volume Plugin
  volume_plugin = mkPlugin "volume" ''
    if [ "$SENDER" = "mouse.clicked" ]; then
      osascript -e "set volume output muted of (get volume settings) to not output muted of (get volume settings)"
    elif [ "$SENDER" = "mouse.scrolled" ]; then
      UP=$([[ "$SCROLL_DELTA" -gt 0 ]] && echo "false" || echo "true")
      if [ "$UP" = "true" ]; then
        osascript -e "set volume output volume ((output volume of (get volume settings)) + 5)"
      else
        osascript -e "set volume output volume ((output volume of (get volume settings)) - 5)"
      fi
    fi

    VOLUME=$(osascript -e "output volume of (get volume settings)")
    MUTED=$(osascript -e "output muted of (get volume settings)")

    if [ "$MUTED" = "true" ]; then
      ICON="󰝟"
    else
      case ''${VOLUME} in
        100) ICON="󰕾" ;;
        9[0-9]) ICON="󰕾" ;;
        8[0-9]) ICON="󰕾" ;;
        7[0-9]) ICON="󰕾" ;;
        6[0-9]) ICON="󰕾" ;;
        5[0-9]) ICON="󰕾" ;;
        4[0-9]) ICON="󰕾" ;;
        3[0-9]) ICON="󰖀" ;;
        2[0-9]) ICON="󰖀" ;;
        1[0-9]) ICON="󰕿" ;;
        [0-9]) ICON="󰕿" ;;
        *) ICON="󰕾"
      esac
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%" icon.padding_right=8
  '';

  # Battery Plugin
  battery_plugin = mkPlugin "battery" ''
    PERCENTAGE=$(pmset -g batt | grep -Eo "[0-9]+%" | cut -d% -f1)
    CHARGING=$(pmset -g batt | grep 'AC Power')

    if [ "$PERCENTAGE" = "" ]; then
      exit 0
    fi

    case ''${PERCENTAGE} in
      9[0-9]|100) ICON="󰁹" ;;
      8[0-9]) ICON="󰂀" ;;
      7[0-9]) ICON="󰂀" ;;
      6[0-9]) ICON="󰁿" ;;
      5[0-9]) ICON="󰁾" ;;
      4[0-9]) ICON="󰁽" ;;
      3[0-9]) ICON="󰁼" ;;
      2[0-9]) ICON="󰁻" ;;
      1[0-9]) ICON="󰁺" ;;
      *) ICON="󰁹"
    esac

    if [ "$CHARGING" != "" ]; then
      ICON="󰂄"
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$PERCENTAGE%" icon.padding_right=8
  '';

  # CPU Plugin
  cpu_plugin = mkPlugin "cpu" ''
    CPU_USAGE=$(top -l 1 | grep -E "^CPU" | grep -Eo '[0-9]+\.[0-9]+%' | head -1 | cut -d. -f1)
    sketchybar --set "$NAME" label="$CPU_USAGE%"
  '';

  # Memory Plugin
  memory_plugin = mkPlugin "memory" ''
    MEMORY_USAGE=$(vm_stat | perl -ne 'printf "%.0f\n", $1 * 4096 / 1024**3 if /Pages free:\s+(\d+)/')
    sketchybar --set "$NAME" label="''${MEMORY_USAGE}GB free"
  '';

  # Media Plugin (TIDAL/General)
  media_plugin = mkPlugin "media" ''
    if [ "$SENDER" = "mouse.clicked" ]; then
      osascript -e 'tell application "System Events" to tell process "TIDAL" to click menu item 1 of menu "Playback" of menu bar 1'
      exit 0
    fi

    TIDAL_INFO=$(osascript -e 'tell application "System Events" to if exists (process "TIDAL") then tell process "TIDAL" to return name of window 1' 2>/dev/null)
    
    if [ "$TIDAL_INFO" != "" ] && [ "$TIDAL_INFO" != "TIDAL" ]; then
       INFO="$TIDAL_INFO"
    else
       sketchybar --set "$NAME" drawing=off
       exit 0
    fi

    if [ ''${#INFO} -gt 35 ]; then
      INFO="$(echo "$INFO" | cut -c1-32)..."
    fi
    sketchybar --set "$NAME" icon="$INFO" label="󰝚" drawing=on
  '';

in
{
  options.modules.darwin.sketchybar = {
    enable = mkOption { type = types.bool; default = false; };
    theme = mkOption {
      type = types.enum [ 
        "laserwave" "catppuccin" "nord" "tokyonight" 
        "gruvbox" "solarized" "dracula" "rose-pine" "onedark" "everforest" 
        "solarized-light" "catppuccin-latte" "gruvbox-light" "nord-light" "github-light" "everforest-light"
      ];
      default = "laserwave";
    };
    workspaces = mkOption { type = types.bool; default = true; };
    frontApp = mkOption { type = types.bool; default = true; };
    clock = mkOption { type = types.bool; default = true; };
    volume = mkOption { type = types.bool; default = true; };
    battery = mkOption { type = types.bool; default = true; };
    cpu = mkOption { type = types.bool; default = true; };
    memory = mkOption { type = types.bool; default = true; };
    media = mkOption { type = types.bool; default = true; };
  };

  config = mkIf cfg.enable {
    services.sketchybar = {
      enable = true;
      config = ''
        # Global Settings
        sketchybar --bar \
          height=32 \
          color=${colors.bg} \
          shadow=on \
          position=top \
          sticky=on \
          padding_left=10 \
          padding_right=10 \
          corner_radius=0 \
          blur_radius=20 \
          font="CaskaydiaMono Nerd Font:Bold:14.0"

        # Default Settings
        sketchybar --default \
          updates=on \
          icon.font="CaskaydiaMono Nerd Font:Bold:16.0" \
          icon.color=${colors.fg} \
          label.font="CaskaydiaMono Nerd Font:Bold:14.0" \
          label.color=${colors.fg} \
          background.color=${colors.item_bg} \
          background.corner_radius=6 \
          background.height=26 \
          padding_left=6 \
          padding_right=6

        ${optionalString cfg.workspaces ''
          ${workspace_controller}
          sketchybar --add event aerospace_workspace_change
          sketchybar --add item workspace_observer left \
            --set workspace_observer drawing=off script="${workspace_controller}" \
            --subscribe workspace_observer aerospace_workspace_change
          sketchybar --set "/space\..*/" label.font="sketchybar-app-font:Regular:16.0"
        ''}

        ${optionalString cfg.frontApp ''
          sketchybar --add item front_app left \
            --set front_app icon=󱂬 label.color=${colors.accent} script="${front_app_plugin}" \
            --subscribe front_app front_app_switched
        ''}

        ${optionalString cfg.clock ''
          sketchybar --add item clock right \
            --set clock icon=󱑒 update_freq=30 script="${clock_plugin}"
        ''}

        ${optionalString cfg.volume ''
          sketchybar --add item volume right \
            --set volume script="${volume_plugin}" update_freq=5 \
            --subscribe volume volume_change mouse.clicked mouse.scrolled
        ''}

        ${optionalString cfg.battery ''
          sketchybar --add item battery right \
            --set battery script="${battery_plugin}" update_freq=60 \
            --subscribe battery power_source_change system_woke
        ''}

        ${optionalString cfg.cpu ''
          sketchybar --add item cpu right \
            --set cpu icon=󰍛 update_freq=2 script="${cpu_plugin}"
        ''}

        ${optionalString cfg.memory ''
          sketchybar --add item memory right \
            --set memory icon=󰘚 update_freq=15 script="${memory_plugin}"
        ''}

        ${optionalString cfg.media ''
          sketchybar --add item media right \
            --set media label=󰝚 \
              icon.font="CaskaydiaMono Nerd Font:Bold:14.0" \
              label.padding_left=14 \
              background.drawing=off \
              script="${media_plugin}" \
              click_script="${media_plugin}" \
              update_freq=5 \
            --subscribe media media_change
        ''}

        sketchybar --update
      '';
    };
    environment.systemPackages = [ pkgs.sketchybar pkgs.aerospace ];
  };
}
