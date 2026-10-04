{ xray }:

xray.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    sed -Ei 's/^(\s*MaxDatagramFrameSize\s*=\s*)1200$/\11500/' \
      transport/internet/hysteria/config.go
    grep -Eq '^\s*MaxDatagramFrameSize\s*=\s*1500$' \
      transport/internet/hysteria/config.go
  '';
})
