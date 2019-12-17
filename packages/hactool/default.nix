{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "hactool";

  src = fetchFromGitHub {
    owner = "SciresM";
    repo = "hactool";
    rev = "0219abfd8395fd7b244d577c22add2f66544735e";
    sha256 = "01818lv17y0jw2rfqvxlnfb9xgyg8pa515039l8414a06cdm0mf2";
  };

  configurePhase = ''
    cp config.mk.template config.mk
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp hactool $out/bin
  '';
}
