[
  (
    { pkgs, lib, config, ... }:
    {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
      gtk = {
        enable = true;
        colorScheme = "dark";
        gtk4.theme = config.gtk.theme;
        theme = {
          name = "catppuccin-macchiato-lavender-compact";
          package = pkgs.catppuccin-gtk.override {
            accents = [ "lavender" ];
            variant = "macchiato";
            size = "compact";
          };
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
        cursorTheme = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 16;
        };
        font = {
          name = "Roboto";
          size = 11;
        };
        gtk2.extraConfig = ''
          gtk-application-prefer-dark-theme=1
        '';
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      };
      qt = {
        enable = true;
        platformTheme = {
          name = "qtct";
          package = pkgs.kdePackages.qt6ct;
        };
        style.name = "kvantum";

        qt6ctSettings = {
          Appearance = {
            icon_theme = config.gtk.iconTheme.name;
          };
        };
      };

      home.pointerCursor = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 16;
        gtk.enable = true;
        x11.enable = true;
      };
    }
  )
]
