{
  buildGoPackage,
  fetchFromGitHub,
  libpcap,
}:
buildGoPackage rec {
  pname = "virtwold";
  version = "23.03.0";

  goPackagePath = "github.com/ScottESanDiego/virtwold";

  src = fetchFromGitHub {
    owner = "ScottESanDiego";
    repo = "virtwold";
    rev = version;
    sha256 = "sha256-fM51aKkqCt5DnC/IJz3iUPc/Tblx5og8wQanPkbf6PY=";
  };

  goDeps = ./deps.nix;

  buildInputs = [
    libpcap
  ];

  meta.mainProgram = "virtwold";
}
