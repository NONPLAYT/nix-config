{ pkgs, ... }:

let
  helper = pkgs.writeShellScript "git-credential-readonly" ''
    if [ "$1" = "get" ]; then
      while IFS= read -r line; do
        case "$line" in host=*) host="''${line#host=}" ;; esac
      done
      entry=$(grep -m1 "$host" ~/.git-credentials 2>/dev/null) || exit 1
      echo "$entry" | ${pkgs.gnused}/bin/sed -E 's|https://([^:]+):([^@]+)@(.+)|protocol=https\nhost=\3\nusername=\1\npassword=\2|'
    fi
  '';
in
{
  environment.systemPackages = with pkgs; [
    diff-so-fancy
    git-crypt
    tig
  ];

  programs.git = {
    enable = true;

    config = {
      user = {
        name = "NONPLAYT";
        email = "nonplay@bxteam.org";
      };

      credential."https://github.com".helper = "${helper}";

      core.editor = "nano";
      init.defaultBranch = "master";

      alias = {
        amend = "commit --amend -m";
        br = "branch";
        co = "checkout";
        cob = "checkout -b";
        st = "status";
        ls = "log --graph --pretty=format:\"%C(yellow)%h%C(auto)%d %Creset%s %C(blue)[%an] %C(green)%ar\"";
        cm = "commit -m";
        ca = "commit -am";
        an = "commit --amend --no-edit";
        # stage everything, new files included, into the last commit
        ana = "!git add -A && git commit --amend --no-edit";
        # finish an `edit` stop: fold everything into it and continue
        arc = "!git add -A && git commit --amend --no-edit && git rebase --continue";
        pl = "pull";
        pr = "pull --rebase";
        pf = "push --force-with-lease";
        rmain = "rebase main";
        rc = "rebase --continue";
        ra = "rebase --abort";
        # git ri [n|ref]: interactive rebase over the last n commits (default 1) or onto ref
        ri = "!f() { case \"\${1:-1}\" in *[!0-9]*) git rebase -i \"$1\" ;; *) git rebase -i HEAD~\${1:-1} ;; esac; }; f";
        # git re <sha>: rebase stopping at <sha> for editing, no todo editor
        re = "!f() { s=$(git rev-parse \"$1\") && GIT_SEQUENCE_EDITOR=\"sed -i 1s/^pick/edit/\" git rebase -i \"$s\"^; }; f";
        # rebase without resetting committer dates to now
        rbd = "rebase --committer-date-is-author-date";
      };
    };
  };
}
