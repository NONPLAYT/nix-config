final: prev: {
  pgtui = prev.callPackage ./pgtui.nix { };
  packweave = prev.callPackage ./packweave.nix { };
}
