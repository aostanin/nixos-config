{ buildPythonPackage, pkgs, fetchFromGitHub, fusepy, pycryptodomex }:

buildPythonPackage rec {
  pname = "ninfs";
  version = "1.7b2";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "ihaveamac";
    repo = "ninfs";
    rev = "v" + version;
    sha256 = "1pzvy7dijrpxdizykafdqfh92a9avfww8f4ymbfj6z06frip2l67";
  };

  propagatedBuildInputs = [
    fusepy
    pycryptodomex
  ];

  makeWrapperArgs = [ "--prefix FUSE_LIBRARY_PATH : ${pkgs.fuse}/lib/libfuse.so" ];
}
