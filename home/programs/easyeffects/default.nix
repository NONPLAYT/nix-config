{ lib
, pkgs
, ...
}:

let
  easyeffectsrc = pkgs.writeText "easyeffectsrc" ''
    [StreamInputs]
    inputDevice=
    visiblePage=pluginsPage

    [StreamOutputs]
    outputDevice=
    plugins=
    visiblePage=pluginsPage

    [Window]
    height=668
    showTrayIcon=false
    width=1251
  '';
in
{
  services.easyeffects.enable = true;
  home.activation.easyeffects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/easyeffects/db"
    if [ ! -f "$HOME/.config/easyeffects/db/easyeffectsrc" ]; then
      cp ${easyeffectsrc} "$HOME/.config/easyeffects/db/easyeffectsrc"
      chmod u+w "$HOME/.config/easyeffects/db/easyeffectsrc"
    fi
  '';
}
