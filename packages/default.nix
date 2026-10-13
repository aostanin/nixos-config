{pkgs}: {
  kokoro-fastapi = pkgs.callPackage ./kokoro-fastapi {};
  polystrata = pkgs.callPackage ./polystrata {};
  splash = pkgs.callPackage ./splash {};
  strata = pkgs.callPackage ./strata {};
  vfio-isolate = pkgs.python3Packages.callPackage ./vfio-isolate {};
  virtwold = pkgs.callPackage ./virtwold {};
}
