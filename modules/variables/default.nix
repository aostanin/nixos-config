{lib, ...}: {
  options = {
    variables = lib.mkOption {
      type = lib.types.attrs;
      default = {
        hasBattery = false;
        hasBacklightControl = false;
        hasDesktop = false;
      };
    };
  };
}
