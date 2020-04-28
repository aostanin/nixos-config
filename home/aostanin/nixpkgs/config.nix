let
  unstable = import <unstable> { };
in
{
  allowUnfree = true;

  packageOverrides = {
    rofi = unstable.rofi.override {
      plugins = [
        unstable.rofi-calc
      ];
    };
  };
}
