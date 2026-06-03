{ ... }:

{
  services.reposilite = {
    enable = true;
    settings = {
      port = 3002;
      hostname = "127.0.0.1";
    };
  };
}
