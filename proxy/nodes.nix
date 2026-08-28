[
  {
    name = "stockholm";
    flag = "🇸🇪";
    fqdn = "stockholm.bxteam.org";
    reality = {
      sni = "stockholm.bxteam.org";
      dest = "127.0.0.1:443";
    };
    bandwidth = {
      node = 200;
      up = 50;
      down = 100;
    };
    inbounds = [
      { group = "personal"; port = 8443; path = "/static/media"; }
      { group = "personal"; protocol = "hysteria"; port = 443; }
    ];
  }
  {
    name = "asgard";
    flag = "";
    fqdn = "asgard.bxteam.org";
    reality = {
      sni = "asgard.bxteam.org";
      dest = "127.0.0.1:443";
    };
    bandwidth = {
      node = 200;
      up = 50;
      down = 100;
    };
    inbounds = [
      { group = "asgard"; port = 8443; path = "/static/media"; }
      { group = "asgard"; protocol = "hysteria"; port = 443; }
    ];
  }
]
