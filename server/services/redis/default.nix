{ ... }:

{
  services.redis.servers.default = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
    save = [
      [ 900 1 ]
      [ 300 10 ]
      [ 60 10000 ]
    ];
  };
}
