{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, libpulseaudio
, openssl
, qt6
,
}:

stdenv.mkDerivation {
  pname = "librepods-airpods";
  version = "0-unstable-2026-08-26";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "harveywuk";
    repo = "librepods";
    rev = "4ed49df0b301ac3e6fba9c81dfbbb6726cc52201";
    hash = "sha256-Ygoqz5lnGMwZkys+Q4c4pyAUI0llvpGZ/ij5E91CkAg=";
  };

  cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" false) ];

  buildInputs = [
    libpulseaudio
    openssl
    qt6.qtbase
    qt6.qtconnectivity
    qt6.qtdeclarative
    qt6.qttools
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  meta = {
    description = "Patched librepods daemon for the noctalia airpods plugin";
    homepage = "https://github.com/harveywuk/librepods";
    license = lib.licenses.gpl3Only;
    mainProgram = "librepods";
    platforms = lib.platforms.linux;
  };
}
