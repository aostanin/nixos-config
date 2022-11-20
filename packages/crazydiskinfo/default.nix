{
  stdenv,
  fetchFromGitHub,
  cmake,
  libatasmart,
  ncurses5,
}:
stdenv.mkDerivation rec {
  name = "crazydiskinfo";

  buildInputs = [
    libatasmart
    ncurses5
  ];

  nativeBuildInputs = [
    cmake
  ];

  src = fetchFromGitHub {
    owner = "otakuto";
    repo = "crazydiskinfo";
    rev = "64c1338e909bd462c854cea7e04df15fec5714f8";
    sha256 = "0dj8yzm52vi196856kby4blad7lhcdhcpz55k1mc6s9m8jbj86sp";
  };

  prePatch = ''
    sed -i s/ncursesw/ncurses/g CMakeLists.txt
    sed -i s/tinfow/tinfo/g CMakeLists.txt
    mkdir -p $out/lib
    ln -s ${ncurses5.out}/lib/libtinfo.so.5 $out/lib/libtinfo.so.5
  '';

  installPhase = ''
    mkdir -p $out/sbin
    mv crazy $out/sbin
  '';
}
