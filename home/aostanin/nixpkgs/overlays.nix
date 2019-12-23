[
  (self: super: {
    unstable = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz) { };

    catt = super.python3Packages.callPackage /etc/nixos/packages/catt { };
    crazydiskinfo = super.callPackage /etc/nixos/packages/crazydiskinfo { };
    dedbae = super.callPackage /etc/nixos/packages/dedbae { };
    hactool = super.callPackage /etc/nixos/packages/hactool { };
    ninfs = super.python3Packages.callPackage /etc/nixos/packages/ninfs { };
    personal-scripts = super.callPackage /etc/nixos/packages/personal-scripts { };
    pidcat = super.callPackage /etc/nixos/packages/pidcat { };
    splitNSP = super.callPackage /etc/nixos/packages/splitNSP { };
  })
]
