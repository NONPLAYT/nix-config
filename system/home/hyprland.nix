{
  config,
  pkgs,
  lib,
  ...
}:
let
  hyprlandPackages = with pkgs; [
    hypridle
    polkit_gnome
    grimblast
    hyprpicker
  ];
in
{
  options = {
    hyprland.enable = lib.mkEnableOption "Enable Hyprland";
  };

  config = lib.mkIf config.hyprland.enable {
    home.packages = hyprlandPackages;

    xdg.configFile = {
      "electron-flags.conf".text = ''
        --enable-features=UseOzonePlatform
        --ozone-platform=wayland
      '';
      "hypr" = {
        source = ./dotfiles/config/hypr;
        recursive = true;
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false;
      systemd.variables = [ "--all" ];
    };
  };
}
