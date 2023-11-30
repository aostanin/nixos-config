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
  version = "0.7.2";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "AnalogJ";
    repo = "scrutiny";
    rev = "v${version}";
    sha256 = "sha256-UYKi+WTsasUaE6irzMAHr66k7wXyec8FXc8AWjEk0qs=";
  };

  vendorHash = "sha256-SiQw6pq0Fyy8Ia39S/Vgp9Mlfog2drtVn43g+GXiQuI=";

  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/collector-metrics --prefix PATH : ${lib.makeBinPath [smartmontools]}
  '';
}
