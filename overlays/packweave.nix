{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "packweave";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/packweavers/packweave/releases/download/v${version}/packweave-linux-x86_64.AppImage";
    hash = "sha256-eATDsfTvmxslRzd0nsWmOsd3xV7SJsmetAU80xSmDk0=";
  };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
    cp -r ${contents}/usr/share/icons $out/share/

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail "Exec=${pname}" "Exec=$out/bin/${pname}" \
      --replace-fail "Categories=" "Categories=Utility;Game;"
  '';

  meta = {
    description = "A Minecraft modpack IDE";
    homepage = "https://github.com/packweavers/packweave";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
