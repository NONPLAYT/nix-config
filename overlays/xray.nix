{ xray }:

xray.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace transport/internet/hysteria/config.go \
      --replace-fail 'MaxDatagramFrameSize = 1200' 'MaxDatagramFrameSize = 1500'
  '';
})
