{
  pkgs,
  lib,
  config,
  ...
}:
let
  username = "nonplay";
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";

  nerdFonts = with pkgs.nerd-fonts; [
    symbols-only
    caskaydia-cove
  ];

  fontPkgs =
    with pkgs;
    [
      font-awesome
      material-design-icons
      jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ]
    ++ nerdFonts;

  packages =
    with pkgs;
    [
      equibop
      dig
      jq
      btop
      duf
      eza
      fd
      killall
      age
      unzip
      zip
      brightnessctl
      pavucontrol
      playerctl
      dex
      easyeffects
      telegram-desktop
      direnv
      wl-clipboard
      ntfs3g
      prismlauncher
      packwiz
      mtr
      nodejs
      bun
      openssl
      gh
      nautilus
      github-copilot-cli
      javaPackages.compiler.temurin-bin-21
    ]
    ++ fontPkgs;
in
{
  imports = [
    ./plasma.nix
    ./hyprland.nix
  ]
  ++ lib.concatMap import [
    ./scripts
    ./programs
    ./services
    ./themes
  ];

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  # important!!!
  plasma.enable = false;
  hyprland.enable = true;

  xdg = {
    inherit configHome;
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;

      desktop = "${homeDirectory}/Desktop";
      documents = "${homeDirectory}/Documents";
      download = "${homeDirectory}/Downloads";
      music = "${homeDirectory}/Music";
      pictures = "${homeDirectory}/Pictures";
      videos = "${homeDirectory}/Videos";

      publicShare = homeDirectory;
      templates = homeDirectory;
    };

    desktopEntries = {
      "blueman-adapters" = {
        name = "Bluetooth Adapters";
        noDisplay = true;
      };
      "micro" = {
        name = "Micro";
        noDisplay = true;
      };
      "btop" = {
        name = "btop++";
        noDisplay = true;
      };
      "htop" = {
        name = "Htop";
        noDisplay = true;
      };
      "kitty" = {
        name = "kitty";
        noDisplay = true;
      };
      "org.gnome.Loupe" = {
        name = "Image Viewer";
        noDisplay = true;
      };
      "org.pulseaudio.pavucontrol" = {
        name = "Volume Control";
        noDisplay = true;
      };

      code = {
        name = "Visual Studio Code";
        genericName = "Text Editor";
        exec = "code %F";
        icon = "${pkgs.vscode}/share/pixmaps/vscode.png";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
          "IDE"
        ];
        mimeType = [ "text/plain" ];
        startupNotify = true;
        settings = {
          StartupWMClass = "Code";
        };
      };
    };

    portal = {
      enable = true;
      xdgOpenUsePortal = true;

      config = lib.mkMerge [
        (lib.mkIf config.plasma.enable {
          kde.default = [
            "kde"
            "gtk"
            "gnome"
          ];
          kde."org.freedesktop.portal.FileChooser" = [ "kde" ];
          kde."org.freedesktop.portal.OpenURI" = [ "kde" ];
        })

        (lib.mkIf config.hyprland.enable {
          hyprland.default = [
            "hyprland"
            "gtk"
            "gnome"
            "termfilechooser"
          ];
          hyprland."org.freedesktop.portal.FileChooser" = [ "termfilechooser" ];
          hyprland."org.freedesktop.portal.OpenURI" = [ "termfilechooser" ];
        })
      ];

      extraPortals =
        with pkgs;
        [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ]
        ++ lib.optionals config.plasma.enable [
          pkgs.kdePackages.xdg-desktop-portal-kde
        ]
        ++ lib.optionals config.hyprland.enable [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-termfilechooser
        ];
    };

    configFile = {
      "JetBrains/idea.vmoptions".text = ''
        -Xms512m
        -Xmx8192m
      '';
    };
  };

  home = {
    inherit username homeDirectory packages;
    stateVersion = "26.05";
    sessionVariables = {
      DISPLAY = ":0";
      BROWSER = "${lib.getExe pkgs.firefox-beta}";
      SHELL = "${lib.getExe pkgs.zsh}";
      EDITOR = "nano";
      VISUAL = "nano";
      GIT_ASKPASS = "";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      IDEA_VM_OPTIONS = "${homeDirectory}/.config/JetBrains/idea.vmoptions";
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  systemd.user.startServices = "sd-switch";
  news.display = "silent";
}
