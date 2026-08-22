{ config, host, lib, xctrlApiPath, xctrlUsers, xctrlGroups, xctrlNodes, xctrlIsNode, ... }:

let
  inherit (lib) optionalAttrs;

  placeholder = config.sops.placeholder;

  node = n: {
    inherit (n) name flag fqdn;
    inbounds = map
      (i: {
        inherit (i) group;
        tag = "vless-${i.group}";
        link = {
          scheme = "vless";
          inherit (i) port;
          params = {
            security = "reality";
            encryption = "none";
            type = "tcp";
            flow = "xtls-rprx-vision";
            fp = "firefox";
            sni = n.reality.sni;
            pbk = placeholder."proxy/nodes/${n.name}/pbk";
            sid = placeholder."proxy/nodes/${n.name}/sid";
          };
        };
      })
      n.inbounds;
  } // optionalAttrs (n.name == host) {
    api = "http://127.0.0.1:10086";
  };

  user = u: {
    inherit (u) name group;
    admin = u.admin or false;
    uuid = placeholder."proxy/users/${u.name}/uuid";
    sub_token = placeholder."proxy/users/${u.name}/sub_token";
  } // optionalAttrs (u ? limit) { inherit (u) limit; }
  // optionalAttrs (u ? expires) { inherit (u) expires; };

  group = g: { inherit (g) name; } // optionalAttrs (g.limit != null) {
    inherit (g) limit;
  };
in
{
  sops.templates.xctrl = {
    path = "/run/secrets/xctrl.json";
    group = "xctrl";
    mode = "0440";
    content = builtins.toJSON ({
      sub_domain = "sub.bxteam.org";
      title = "relay for {user}";
      support_url = "https://t.me/nonplay";
      token = placeholder."proxy/token";
      state_dir = "/var/lib/xctrl";
      serve_listen = "127.0.0.1:3001";
      agent_listen = "127.0.0.1:10086";
      admin_listen = "127.0.0.1:10087";
      controller_api = "http://127.0.0.1:10087";
      xray_api = "127.0.0.1:10085";
      api_path = xctrlApiPath;
      quota = {
        reset_day = 28;
        reset_hour = 1;
        reset_minute = 0;
        reset_utc_offset_hours = 3;
      };
      happ_routing = builtins.toJSON
        (builtins.fromJSON (builtins.readFile ./profiles/happ-routing.json));
      clash = {
        selector = "PROXY";
        auto = "⚡️ Авто";
        profile = builtins.readFile ./profiles/clash.yaml;
      };
      groups = map group xctrlGroups;
      nodes = map node xctrlNodes;
      users = map user xctrlUsers;
    } // optionalAttrs xctrlIsNode {
      node = host;
    });
  };

  users.groups.xctrl = { };
  users.users.xctrl = {
    isSystemUser = true;
    group = "xctrl";
  };
}
