{pkgs}: {
  personal-scripts = pkgs.callPackage ./personal-scripts {};
  pidcat = pkgs.callPackage ./pidcat {};
  scrutiny = pkgs.callPackage ./scrutiny {};
  vfio-isolate = pkgs.python3Packages.callPackage ./vfio-isolate {};
  virtwold = pkgs.callPackage ./virtwold {};
}
