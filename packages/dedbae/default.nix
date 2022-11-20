{
  stdenv,
  fetchgit,
}:
stdenv.mkDerivation {
  name = "dedbae";

  src = fetchgit {
    url = "https://gitlab.com/roothorick/dedbae.git";
    rev = "87b08da7c1e73c481cae635136240098013e832e";
    fetchSubmodules = true;
    sha256 = "11z48688gv81ishn3810f2aam7hilbdw961a92kq8nxd2s7lqqyc";
  };

  installPhase = ''
    mkdir -p $out
    cp -r bin $out
  '';

  RELEASE = 1; # Enable optimizations
}
