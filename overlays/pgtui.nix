{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "pgtui";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "pgplex";
    repo = "pgtui";
    tag = "v${version}";
    hash = "sha256-qGWKsjF5lYWxtXHWib2QK/LtNW7RAEnlmRGZREW2wKg=";
  };

  vendorHash = "sha256-jdwl+ganflen4vG1JjpazkxrRzT7eGWYj6UHmiwlono=";

  subPackages = [ "cmd/pgtui" ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Terminal UI for PostgreSQL with vim-style navigation";
    homepage = "https://github.com/pgplex/pgtui";
    license = lib.licenses.asl20;
    mainProgram = "pgtui";
    platforms = lib.platforms.unix;
  };
}
