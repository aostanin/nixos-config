{ stdenv
, fetchFromGitHub
, fetchpatch
, cmake
, pkgconfig
, SDL2
, SDL
, SDL2_ttf
, openssl
, spice-protocol
, fontconfig
, libX11
, freefont_ttf
, nettle
, libconfig
, wayland
, libpthreadstubs
, libXdmcp
, libXfixes
, libbfd
, libXi
}:

stdenv.mkDerivation rec {
  pname = "looking-glass-client";
  version = "B2-rc4";

  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = version;
    sha256 = "0w8wkrnnvab22jqvii62h6j07kfrv90813ch7yhrs4yhqiv97wm8";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    SDL
    SDL2
    SDL2_ttf
    openssl
    spice-protocol
    fontconfig
    libX11
    freefont_ttf
    nettle
    libconfig
    wayland
    libpthreadstubs
    libXdmcp
    libXfixes
    libbfd
    cmake
    libXi
  ];

  enableParallelBuilding = true;

  sourceRoot = "source/client";

  NIX_CFLAGS_COMPILE = "-msse4.2";

  installPhase = ''
    mkdir -p $out/bin
    mv looking-glass-client $out/bin
  '';

  meta = with stdenv.lib; {
    description = "A KVM Frame Relay (KVMFR) implementation";
    longDescription = ''
      Looking Glass is an open source application that allows the use of a KVM
      (Kernel-based Virtual Machine) configured for VGA PCI Pass-through
      without an attached physical monitor, keyboard or mouse. This is the final
      step required to move away from dual booting with other operating systems
      for legacy programs that require high performance graphics.
    '';
    homepage = "https://looking-glass.hostfission.com/";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.alexbakker ];
    platforms = [ "x86_64-linux" ];
  };
}
