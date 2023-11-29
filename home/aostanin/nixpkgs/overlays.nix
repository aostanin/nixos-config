[
  (
    self: super: {
      # TODO: Make this compatible with host systems
      crazydiskinfo = super.callPackage ../../../packages/crazydiskinfo {};
      dedbae = super.callPackage ../../../packages/dedbae {};
      hactool = super.callPackage ../../../packages/hactool {};
      immersed = super.callPackage ../../../packages/immersed {};
      ninfs = super.python3Packages.callPackage ../../../packages/ninfs {};
      nsz = super.python3Packages.callPackage ../../../packages/nsz {};
      personal-scripts = super.callPackage ../../../packages/personal-scripts {};
      pidcat = super.callPackage ../../../packages/pidcat {};
      scrutiny = super.callPackage ../../../packages/scrutiny {};
      splitNSP = super.callPackage ../../../packages/splitNSP {};
      upp = super.python3Packages.callPackage ../../../packages/upp {};
      vfio-isolate = super.python3Packages.callPackage ../../../packages/vfio-isolate {};
      virtwold = super.callPackage ../../../packages/virtwold {};

      zfs = super.zfs.override {
        # Needed for zed to send emails: https://github.com/NixOS/nixpkgs/issues/132464
        enableMail = true;
      };

      libvirt = super.libvirt.overrideAttrs (old: {
        postPatch =
          old.postPatch
          + ''
            # viriscsitest fails on aarch64
            sed -i '/viriscsitest/d' tests/meson.build
          '';
      });
    }
  )
]
