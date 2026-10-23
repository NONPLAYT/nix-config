{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 263;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      window-size = mkTuple [ 100 100 ];
    };

    "org/gtk/settings/file-chooser" = {
      window-position = mkTuple [ (-1) (-1) ];
      window-size = mkTuple [ 300 100 ];
    };

    "org/cinnamon/desktop/default-applications/terminal" = {
      exec = "kitty";
    };
  };
}
