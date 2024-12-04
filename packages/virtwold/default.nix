{
  buildGoModule,
  fetchFromGitHub,
  libpcap,
  pkg-config,
  libvirt,
}:
buildGoModule rec {
  pname = "virtwold";
  version = "23.12.0";

  src = fetchFromGitHub {
    owner = "ScottESanDiego";
    repo = "virtwold";
    rev = version;
    sha256 = "sha256-HFJWG0s5FRcJibnw18iO6dtFO5K4XAtePgLRUCTo8Go=";
  };

  vendorHash = "sha256-glRLE/6pKKRYUb4cVbKWjdbgk50mtpc82E3QsFVu4Tk=";

  buildInputs = [
    libpcap
    libvirt
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  meta.mainProgram = "virtwold";
}
