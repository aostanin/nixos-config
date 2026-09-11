{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    gnupg.enable = true;
  };

  services.kanshi.settings = [
    {
      profile.name = "undocked";
      profile.outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          scale = 1.0;
        }
      ];
    }
  ];
}
