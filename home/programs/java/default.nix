{ pkgs, lib, config, ... }:

let
  jdks = with pkgs.javaPackages.compiler.temurin-bin; {
    "17" = jdk-17;
    "21" = jdk-21;
    "25" = jdk-25;
  };

  jdkPath = v: "${config.home.homeDirectory}/.jdks/temurin-${v}";
in
{
  programs.java = {
    enable = true;
    package = jdks."25";
  };

  home.file =
    lib.mapAttrs' (v: jdk: lib.nameValuePair ".jdks/temurin-${v}" { source = jdk; }) jdks
    // {
      ".gradle/gradle.properties".text = ''
        org.gradle.java.installations.paths=${lib.concatMapStringsSep "," jdkPath (lib.attrNames jdks)}
        org.gradle.java.installations.auto-detect=false
        org.gradle.java.installations.auto-download=false
      '';
    };
}
