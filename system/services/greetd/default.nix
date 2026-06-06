{ pkgs, config, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd '${pkgs.niri}/bin/niri-session' --remember --remember-session";
        user = "greeter";
      };
    };
  };
}
