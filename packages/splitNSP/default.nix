{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "splitNSP";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "AnalogMan151";
    repo = "splitNSP";
    rev = "cc2d9ee15d5cec20aaeff5ed6897bb3b9dab420b";
    sha256 = "198hw0yjvz754j2glf3w3j4fl4w8k73lz5m61nqyr4sg7hhhjji5";
  };

  buildInputs = with pkgs; [
    python3
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp splitNSP.py $out/bin/splitNSP
    chmod +x $out/bin/splitNSP
  '';
}
