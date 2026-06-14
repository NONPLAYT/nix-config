{ pkgs, config, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "nonplay";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd '${pkgs.niri}/bin/niri-session' --remember --remember-session";
        user = "greeter";
      };
    };
  };
}
