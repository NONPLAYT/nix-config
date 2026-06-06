{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      cnijfilter2
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = false;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}
