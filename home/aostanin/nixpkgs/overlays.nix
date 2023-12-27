[
  (
    self: super: {
      # TODO: Make this compatible with host systems
      personal-scripts = super.callPackage ../../../packages/personal-scripts {};
      pidcat = super.callPackage ../../../packages/pidcat {};
      scrutiny = super.callPackage ../../../packages/scrutiny {};
      vfio-isolate = super.python3Packages.callPackage ../../../packages/vfio-isolate {};
      virtwold = super.callPackage ../../../packages/virtwold {};

      zfs = super.zfs.override {
        # Needed for zed to send emails: https://github.com/NixOS/nixpkgs/issues/132464
        enableMail = true;
      };
    }
  )
]
