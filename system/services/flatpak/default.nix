{ inputs, ... }:

{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    packages = [
      "com.discordapp.Discord"
      "org.vinegarhq.Sober"
      "org.vinegarhq.Vinegar"
      "ch.tlaun.TL"
      "com.soulfiremc.soulfire"
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
