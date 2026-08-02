let
  pgTunnel =
    { lib, pkgs, ... }:
    let
      localPort = 15432;
    in
    {
      systemd.user.services.pg-tunnel = {
        Unit.Description = "ssh tunnel to stockholm postgres";

        Service = {
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe pkgs.openssh)
            "-N stockholm"
            "-L ${toString localPort}:127.0.0.1:5432"
            "-o ExitOnForwardFailure=yes"
            "-o ServerAliveInterval=30"
            "-o ServerAliveCountMax=3"
          ];
          Restart = "always";
          RestartSec = 30;
        };

        Install.WantedBy = [ "default.target" ];
      };
    };

  more =
    { ... }:
    {
      services = {
        ssh-agent.enable = true;

        gnome-keyring = {
          enable = true;
          components = [ "secrets" ];
        };

        blueman-applet.enable = false;
      };
    };
in
[
  more
  pgTunnel
]
