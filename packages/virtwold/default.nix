{
  pkgs,
  buildGoPackage,
  fetchFromGitHub,
  libpcap,
}:
buildGoPackage rec {
  pname = "virtwold";
  version = "21.12.0";

  goPackagePath = "github.com/ScottESanDiego/virtwold";

  src = fetchFromGitHub {
    owner = "ScottESanDiego";
    repo = "virtwold";
    rev = version;
    sha256 = "sha256-2WGnDcsGvVq8obdUZ+JykSPmcvtPDjoE08Fals2Ee8k=";
  };

  goDeps = ./deps.nix;

  buildInputs = [
    libpcap
  ];
}
