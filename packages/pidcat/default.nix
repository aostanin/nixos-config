{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "pidcat";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "JakeWharton";
    repo = "pidcat";
    rev = "61cd1ee1beabfa14eb5fbe21eb90c192d96aebc5";
    hash = "sha256-exswTRhx89W22tynerd5Bg0Q4BxhV0KC05a+VCEqmL4=";
  };

  buildInputs = with pkgs; [
    python3
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp pidcat.py $out/bin/pidcat
    chmod +x $out/bin/pidcat
  '';
}
