{
  buildGoModule,
  fetchFromGitHub,
  libpcap,
  pkg-config,
  libvirt,
}:
buildGoModule rec {
  pname = "virtwold";
  version = "25.10.0";

  src = fetchFromGitHub {
    owner = "ScottESanDiego";
    repo = "virtwold";
    rev = version;
    sha256 = "sha256-1oKL0v8H9Hb0ISMMP7Y5reReqV/Gh5/x/B2YBEzxeJ0=";
  };

  vendorHash = "sha256-ungDRueod3qdht07wI9zfPcGbOcl19bM997QcL+8Fok=";

  buildInputs = [
    libpcap
    libvirt
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  meta.mainProgram = "virtwold";
}
