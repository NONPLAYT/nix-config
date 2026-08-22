[
  {
    name = "stockholm";
    flag = "🇸🇪";
    fqdn = "repo.bxteam.org";
    reality = {
      sni = "repo.bxteam.org";
      dest = "127.0.0.1:443";
    };
    inbounds = [
      { group = "personal"; port = 8443; }
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
    inbounds = [
      { group = "asgard"; port = 8443; }
    ];
  }
]
