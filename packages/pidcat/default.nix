{ pkgs, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "pidcat";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "JakeWharton";
    repo = "pidcat";
    rev = version;
    sha256 = "0jfkyvh39wcyvsa6q21nd5nibrbx7vhf35axlfnr6hd89iv1r997";
  };

  buildInputs = with pkgs; [
    python2
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp pidcat.py $out/bin/pidcat
    chmod +x $out/bin/pidcat
  '';
}
