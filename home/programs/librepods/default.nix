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

      airpods_wanted() {
        [ -r "$state_file" ] || return 1
        jq -e '.connected == true' "$state_file" >/dev/null 2>&1
      }

      bt_sink() {
        pw-dump | jq -r --arg a "$mac_us" --arg b "$mac_cn" '
          [ .[]
            | select(.type == "PipeWire:Interface:Node")
            | .info.props as $p
            | select($p["media.class"] == "Audio/Sink")
            | select(($p["node.name"] | test($a)) or ($p["node.name"] | test($b)))
            | .id ] | first // empty'
      }

      named_node() { # $1 = node.name
        pw-dump | jq -r --arg n "$1" '
          [ .[]
            | select(.type == "PipeWire:Interface:Node")
            | select(.info.props["node.name"] == $n)
            | .id ] | first // empty'
      }

      configured() { # $1 = Sink | Source -> node.name of the current default
        wpctl status | awk -v k="Audio/$1" '$2 == k { print $3 }' | tail -n1
      }

      is_airpods() {
        case "$1" in
          *"$mac_us"*|*"$mac_cn"*) return 0 ;;
          *) return 1 ;;
        esac
      }

      take() { # $1 = node id
        if [ -n "$1" ]; then
          wpctl set-default "$1"
        fi
      }

      pin_source() {
        local deadline=$(( SECONDS + 20 ))
        while :; do
          if [ "$(configured Source)" = "$mic_source" ]; then
            return
          fi
          take "$(named_node "$mic_source")"
          if [ "$SECONDS" -ge "$deadline" ]; then
            return
          fi
          sleep 1
        done
      }

      sink_to_fallback() {
        local deadline=$(( SECONDS + 20 ))
        while :; do
          if [ "$(configured Sink)" = "$fallback_sink" ]; then
            return
          fi
          take "$(named_node "$fallback_sink")"
          if [ "$SECONDS" -ge "$deadline" ]; then
            return
          fi
          sleep 1
        done
      }

      sink_to_airpods() { # non-zero when they never showed up
        local deadline=$(( SECONDS + 20 ))
        while :; do
          if is_airpods "$(configured Sink)"; then
            return 0
          fi
          take "$(bt_sink)"
          if [ "$SECONDS" -ge "$deadline" ]; then
            return 1
          fi
          sleep 1
        done
      }

      apply() {
        pin_source

        if airpods_wanted && sink_to_airpods; then
          return
        fi

        sink_to_fallback
      }

      apply

      inotifywait -q -m -e create,moved_to,close_write,delete --format '%f' "$state_dir" |
        while read -r name; do
          if [ "$name" = "status.json" ]; then
            apply
          fi
        done
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
      Description = "Move playback to the AirPods while they are connected, keeping the microphone on the fifine";
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
