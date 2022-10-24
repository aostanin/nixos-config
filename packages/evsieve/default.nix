{ pkgs, fetchFromGitHub, rustPlatform, libevdev }:

rustPlatform.buildRustPackage rec {
  pname = "evsieve";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "KarsMulder";
    repo = "evsieve";
    rev = "v${version}";
    sha256 = "sha256-R/y3iyKGE4dzAyNnDwrMCr8JFshYJwNcgHQ8UbtuRj8=";
  };

  cargoSha256 = "sha256-jkm+mAHejCBZFalUbJNaIxtIl2kwnlPR2wsaYlcfSz8=";

  buildInputs = [
    libevdev
  ];
}
