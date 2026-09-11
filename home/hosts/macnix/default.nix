{
  pkgs,
  lib,
  inputs,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    niri = {
      # VirtIO GPU reports cursor bitmaps/coordinates incorrectly under UTM,
      # causing an upside-down cursor offset by the notch height. Render the
      # cursor with the rest of the frame to bypass the broken cursor plane.
      extraDebug = "disable-cursor-plane";
    };
  };

  services.kanshi.settings = [
    {
      profile.name = "default";
      profile.outputs = [
        {
          criteria = "Virtual-1";
          status = "enable";
          scale = 1.0;
          mode = "1920x1200";
          position = "0,0";
        }
      ];
    }
  ];
}
