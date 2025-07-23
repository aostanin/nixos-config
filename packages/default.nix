{pkgs}: {
  orca-slicer-appimage = pkgs.callPackage ./orca-slicer-appimage {};
  personal-scripts = pkgs.callPackage ./personal-scripts {};
  pidcat = pkgs.callPackage ./pidcat {};
  vfio-isolate = pkgs.python3Packages.callPackage ./vfio-isolate {};
  virtwold = pkgs.callPackage ./virtwold {};
}
