final: prev: {
  librepods-airpods = prev.callPackage ./librepods-airpods.nix { };
  packweave = prev.callPackage ./packweave.nix { };
  pgtui = prev.callPackage ./pgtui.nix { };
  rkn-block-checker = prev.callPackage ./rkn-block-checker.nix { };
  xray = prev.callPackage ./xray.nix { inherit (prev) xray; };
}
