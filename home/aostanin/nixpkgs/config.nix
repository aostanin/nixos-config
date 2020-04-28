let
  unstable = import <unstable> { };
in
{
  allowUnfree = true;

  packageOverrides = pkgs: rec {
    ark = pkgs.ark.override {
      unfreeEnableUnrar = true;
    };

    beets = pkgs.beets.override {
      enableSonosUpdate = false;
    };

    scream-receivers = pkgs.scream-receivers.override {
      pulseSupport = true;
    };

    wine = pkgs.wine.override {
      wineBuild = "wineWow";
    };
  };

  unstable.packageOverrides = pkgs: rec {
    rofi = unstable.rofi.override {
      plugins = [
        unstable.rofi-calc
      ];
    };
  };
}
