# TODO: Consider moving to separate repo
{
  stdenv,
  lib,
  pkgs,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "personal-scripts";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [makeWrapper];

  installPhase = with pkgs; ''
    mkdir -p $out
    cp -r bin $out
    for i in $out/bin/*; do
      wrapProgram $i --prefix PATH : ${lib.makeBinPath [
      ffmpeg
    ]}
    done
  '';
}
