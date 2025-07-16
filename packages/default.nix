{pkgs}: {
  inhibit-bridge = pkgs.callPackage ./inhibit-bridge {};
  personal-scripts = pkgs.callPackage ./personal-scripts {};
  pidcat = pkgs.callPackage ./pidcat {};
  vfio-isolate = pkgs.python3Packages.callPackage ./vfio-isolate {};
  virtwold = pkgs.callPackage ./virtwold {};
}
