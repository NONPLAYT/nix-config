{ config, ... }:

{
  services.kura.runner = {
    enable = true;
    serverUrl = "https://stockholm.bxteam.org";
    tokenFile = config.sops.secrets."home/kura/runner-token".path;
  };
}
