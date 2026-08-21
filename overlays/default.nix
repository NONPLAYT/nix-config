final: prev: {
  packweave = prev.callPackage ./packweave.nix { };
  pgtui = prev.callPackage ./pgtui.nix { };
  rkn-block-checker = prev.callPackage ./rkn-block-checker.nix { };
}
