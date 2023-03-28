{
  lib,
  pkgs,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  smartmontools,
}:
buildGoModule rec {
  pname = "scrutiny";
  version = "0.6.0";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "AnalogJ";
    repo = "scrutiny";
    rev = "v${version}";
    sha256 = "sha256-zkw+41UJRXi3eQO4YEMq8iAqhFjTTMyinLGCBN4Oc0Y=";
  };

  vendorSha256 = "sha256-eB2Zmd537psC0QU2SkWlamLC5qw0HwFo4IxWgQXfxmQ=";

  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/collector-metrics --prefix PATH : ${lib.makeBinPath [smartmontools]}
  '';
}
