{ config, ... }:

{
  services.mtprotoproxy = {
    enable = true;

    port = 8443;

    users = {
      tg = config.sops.placeholder."stockholm/mtproto/secret";
    };

    secureOnly = true;

    extraConfig = {
      MODES = {
        classic = false;
        secure = false;
        tls = true;
      };

      TLS_DOMAIN = "yandex.ru";
    };
  };
}
