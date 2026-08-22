{ host, lib, ... }:

let
  nodes = import ./nodes.nix;

  isNode = lib.any (n: n.name == host) nodes;
  apiPath = "/xctrl";
  isController = host == "stockholm";
in
{
  _module.args = {
    xctrlUsers = import ./users.nix;
    xctrlGroups = import ./groups.nix;
    xctrlNodes = nodes;
    xctrlIsNode = isNode;
    xctrlApiPath = apiPath;
  };

  imports =
    lib.optionals (isNode || isController) [ ./config.nix ]
    ++ lib.optionals isNode [ ./xray.nix ./agent.nix ]
    ++ lib.optional isController ./controller.nix;
}
