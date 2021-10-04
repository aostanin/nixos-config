[
  (
    self: super: {
      # TODO: Make this compatible with host systems
      crazydiskinfo = super.callPackage ../../../packages/crazydiskinfo { };
      dedbae = super.callPackage ../../../packages/dedbae { };
      hactool = super.callPackage ../../../packages/hactool { };
      ninfs = super.python3Packages.callPackage ../../../packages/ninfs { };
      nsz = super.python3Packages.callPackage ../../../packages/nsz { };
      personal-scripts = super.callPackage ../../../packages/personal-scripts { };
      pidcat = super.callPackage ../../../packages/pidcat { };
      splitNSP = super.callPackage ../../../packages/splitNSP { };
      vfio-isolate = super.python3Packages.callPackage ../../../packages/vfio-isolate { };
    }
  )
]
