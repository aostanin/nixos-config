{pkgs}: {
  kokoro-fastapi = pkgs.callPackage ./kokoro-fastapi {};
  splash = pkgs.callPackage ./splash {};
  vfio-isolate = pkgs.python3Packages.callPackage ./vfio-isolate {};
  virtwold = pkgs.callPackage ./virtwold {};
}
