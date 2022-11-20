{
  pkgs,
  buildGoModule,
  fetchFromGitHub,
  libpcap,
}:
buildGoModule rec {
  pname = "virtwold";
  version = "21.12.0";

  src = fetchFromGitHub {
    owner = "ScottESanDiego";
    repo = "virtwold";
    rev = version;
    sha256 = "sha256-2WGnDcsGvVq8obdUZ+JykSPmcvtPDjoE08Fals2Ee8k=";
  };

  vendorSha256 = "sha256-0+Rc7QXzmh2f5Y4ULTcOB3N4yw/WB6fVsqu3K2Hnyv0=";

  buildInputs = [
    libpcap
  ];
}
