{
  pkgs,
  inputs,
  ...
}: {
  wayland.windowManager.sway.extraSessionCommands = ''
    # VirtIO GPU reports cursor bitmaps/coordinates incorrectly under UTM,
    # causing an upside-down cursor offset by the notch height. Force software
    # cursor rendering to bypass the broken hardware cursor plane entirely.
    export WLR_NO_HARDWARE_CURSORS=1
  '';

  localModules = {
    common.enable = true;

    desktop.enable = true;

    sway = {
      primaryOutput = "Virtual-1";
      output = {
        "Virtual-1" = {
          enable = "";
          mode = "1920x1200";
          position = "0 0";
        };
      };
    };
  };
}
