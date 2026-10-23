{ lib, ... }:

{
  options.proxy.adminForwards = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = ''
            TCP port an admin dials through the VPN, on any public address.
            Matched by port, not address: clients keep private and reserved
            ranges out of the tunnel, so a magic address never reaches xray.
          '';
        };
        target = lib.mkOption {
          type = lib.types.str;
          description = "host:port on the node the connection is redirected to.";
        };
      };
    });
    default = { };
    description = ''
      Loopback services on this node that admins reach through xray by dialling
      a fixed port. Everyone else goes out to the real destination as usual.
    '';
  };
}
