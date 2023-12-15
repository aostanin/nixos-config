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

      libvirt = super.libvirt.overrideAttrs (old: {
        postPatch =
          old.postPatch
          + ''
            # viriscsitest fails on aarch64
            sed -i '/viriscsitest/d' tests/meson.build
          '';
      });

      # Support sixel graphics.
      # TODO: Remove once released
      tmux = super.tmux.overrideAttrs (x: {
        configureFlags =
          (x.configureFlags or [])
          ++ ["--enable-sixel"];
        src = super.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          rev = "bdf8e614af34ba1eaa8243d3a818c8546cb21812";
          hash = "sha256-ZMlpSOmZTykJPR/eqeJ1wr1sCvgj6UwfAXdpavy4hvQ=";
        };
        patches = [];
      });
    }
  )
]
