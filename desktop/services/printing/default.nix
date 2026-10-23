{ pkgs, modulesPath, ... }:

let
  ippUsb = "services/printing/ipp-usb.nix";
in
{
  disabledModules = [ ippUsb ];
  imports = [
    ({ config, lib, pkgs, ... }@args:
      let
        m = import (modulesPath + "/${ippUsb}") args;
        inherit (m.config) content;
      in
      m // {
        config = m.config // {
          content = content // {
            services = content.services // {
              avahi = removeAttrs content.services.avahi [ "publish" ];
            };
          };
        };
      })
  ];

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      cups-filters
    ];
  };

  hardware.printers = {
    ensureDefaultPrinter = "Canon_MP190";
    ensurePrinters = [
      {
        name = "Canon_MP190";
        description = "Canon PIXMA MP190";
        location = "USB";
        deviceUri = "usb://Canon/MP190%20series?serial=916B3B&interface=1";
        model = "gutenprint.5.3://bjc-MULTIPASS-MP190/expert";
        ppdOptions.PageSize = "A4";
      }
    ];
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  services.ipp-usb.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
    };
  };
}
