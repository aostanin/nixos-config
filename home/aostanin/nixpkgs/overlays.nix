[
  (self: super: {
    unstable = import <unstable> { };

    # TODO: Make this compatible with host systems
    catt = super.python3Packages.callPackage ../../../packages/catt { };
    crazydiskinfo = super.callPackage ../../../packages/crazydiskinfo { };
    dedbae = super.callPackage ../../../packages/dedbae { };
    hactool = super.callPackage ../../../packages/hactool { };
    ninfs = super.python3Packages.callPackage ../../../packages/ninfs { };
    personal-scripts = super.callPackage ../../../packages/personal-scripts { };
    pidcat = super.callPackage ../../../packages/pidcat { };
    splitNSP = super.callPackage ../../../packages/splitNSP { };
  })
]
