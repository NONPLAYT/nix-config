{ pkgs, lib, ... }:
let
  airpodsMac = "34:0E:22:8E:5E:90";

  fallbackSink = "alsa_output.usb-3142_fifine_Headset-00.analog-stereo";

  micSource = "easyeffects_source";

  macUnderscored = builtins.replaceStrings [ ":" ] [ "_" ] airpodsMac;

  audioFollow = pkgs.writeShellApplication {
    name = "airpods-audio-follow";
    runtimeInputs = [ pkgs.pipewire pkgs.wireplumber pkgs.jq pkgs.inotify-tools ];
    text = ''
      mac_us=${lib.escapeShellArg macUnderscored}
      mac_cn=${lib.escapeShellArg airpodsMac}
      fallback_sink=${lib.escapeShellArg fallbackSink}
      mic_source=${lib.escapeShellArg micSource}

      state_dir="''${LIBREPODS_STATE:-''${XDG_STATE_HOME:-$HOME/.local/state}/librepods}"
      state_file="$state_dir/status.json"

      worn() {
        [ -r "$state_file" ] || return 1
        jq -e '.connected == true and (.left.in_ear == true or .right.in_ear == true)' \
          "$state_file" >/dev/null 2>&1
      }

      bt_sink() {
        pw-dump | jq -r --arg a "$mac_us" --arg b "$mac_cn" '
          [ .[]
            | select(.type == "PipeWire:Interface:Node")
            | .info.props as $p
            | select($p["media.class"] == "Audio/Sink")
            | select(($p["node.name"] | contains($a)) or ($p["node.name"] | contains($b)))
            | .id ] | first // empty'
      }

      named_node() { # $1 = node.name
        pw-dump | jq -r --arg n "$1" '
          [ .[]
            | select(.type == "PipeWire:Interface:Node")
            | select(.info.props["node.name"] == $n)
            | .id ] | first // empty'
      }

      current() { # $1 = sink | source -> node.name of the effective default
        pw-dump | jq -r --arg k "default.audio.$1" '
          [ .[]
            | select(.type == "PipeWire:Interface:Metadata")
            | select(.props["metadata.name"] == "default")
            | .metadata[]
            | select(.key == $k)
            | .value.name ] | first // empty'
      }

      is_airpods() {
        case "$1" in
          *"$mac_us"*|*"$mac_cn"*) return 0 ;;
          *) return 1 ;;
        esac
      }

      pin_source() {
        if [ "$(current source)" != "$mic_source" ]; then
          local id
          id="$(named_node "$mic_source")"
          if [ -n "$id" ]; then
            wpctl set-default "$id"
          fi
        fi
      }

      previous=""

      to_airpods() {
        local now
        now="$(current sink)"
        if ! is_airpods "$now"; then
          previous="$now"
        fi

        local deadline=$(( SECONDS + 30 )) id
        while worn; do
          if is_airpods "$(current sink)"; then
            break
          fi
          id="$(bt_sink)"
          if [ -n "$id" ]; then
            wpctl set-default "$id"
          fi
          if [ "$SECONDS" -ge "$deadline" ]; then
            break
          fi
          sleep 1
        done
        pin_source
      }

      to_previous() {
        local target id
        for target in "$previous" "$fallback_sink"; do
          [ -n "$target" ] || continue
          id="$(named_node "$target")"
          if [ -n "$id" ]; then
            wpctl set-default "$id"
            break
          fi
        done
        previous=""
        pin_source
      }

      if worn; then
        was=1
        to_airpods
      else
        was=0
        if is_airpods "$(current sink)"; then
          to_previous
        fi
        pin_source
      fi

      while read -r name; do
        [ "$name" = "status.json" ] || continue

        if worn; then
          now=1
        else
          now=0
        fi
        [ "$now" != "$was" ] || continue

        if [ "$now" = 0 ]; then
          sleep 1.5
          if worn; then
            continue
          fi
          was=0
          to_previous
        else
          was=1
          to_airpods
        fi
      done < <(inotifywait -q -m -e create,moved_to,close_write,delete --format '%f' "$state_dir")
    '';
  };
in
{
  home.packages = [ pkgs.librepods-airpods ];

  systemd.user.services.librepods = {
    Unit = {
      Description = "librepods AirPods daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Environment = [
        "QT_LOGGING_RULES=openpods.debug=false"
        "PATH=${lib.makeBinPath [ pkgs.bluez pkgs.systemd pkgs.libnotify ]}"
      ];
      ExecStart = "${lib.getExe pkgs.librepods-airpods} --headless";
      Restart = "on-failure";
      RestartSec = 5;

      UMask = "0077";
      StateDirectory = "librepods";
      StateDirectoryMode = "0700";
      ConfigurationDirectory = "AirPodsTrayApp";
      ConfigurationDirectoryMode = "0700";
      PrivateTmp = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictAddressFamilies = "AF_UNIX AF_BLUETOOTH AF_NETLINK";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.airpods-audio-follow = {
    Unit = {
      Description = "Move playback to the AirPods while one is in an ear, keeping the microphone on the fifine";
      Requires = [ "librepods.service" ];
      After = [
        "graphical-session.target"
        "librepods.service"
        "pipewire.service"
        "wireplumber.service"
        "easyeffects.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Environment = [ "LIBREPODS_STATE=%S/librepods" ];
      ExecStart = lib.getExe audioFollow;
      Restart = "always";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
