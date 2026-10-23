{ pkgs, inputs, ... }:

let
  initialPrefs = builtins.toJSON {
    extensions.theme.system_theme = 1; # GTK
  };
in
{
  imports = [ inputs.helium.homeModules.default ];

  programs.helium = {
    enable = true;
    flags = [
      "--close-window-with-last-tab=never"
      "--enable-features=HeliumMiddleClickAutoscroll"
    ];
    package = (pkgs.callPackage (inputs.helium + "/helium.nix") { }).overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        echo '${initialPrefs}' > $out/opt/helium/initial_preferences
      '';
    });
  };
}
