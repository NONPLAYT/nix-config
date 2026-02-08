{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    git-crypt
    tig
  ];

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "NONPLAYT";
        email = "nonplay@bxteam.org";
      };

      credential."https://github.com".helper = "!gh auth git-credential";

      core.editor = "nano";
      init.defaultBranch = "master";

      alias = {
        amend = "commit --amend -m";
        br = "branch";
        co = "checkout";
        cob = "checkout -b";
        st = "status";
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        rc = "rebase --continue";
      };
    };
  };
}
