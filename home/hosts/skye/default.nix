{
  pkgs,
  config,
  lib,
  secrets,
  inputs,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    sway = {
      useNetworkManager = true;
      primaryOutput = "eDP-1";
      wallpaper = "${inputs.nixos-artwork}/wallpapers/nix-wallpaper-nineish-dark-gray.png";
      workspaceOutputAssign = builtins.map (x: {
        workspace = builtins.toString x;
        output =
          (
            # 2 workspaces per monitor, except 7-9 on main monitor
            if (lib.mod x 3) == 1 || x > 6
            then [secrets.monitors.lg.name]
            else if (lib.mod x 3) == 2
            then [secrets.monitors.dell.name]
            else []
          )
          ++ (
            if (lib.mod x 2) == 0
            then [secrets.monitors.parents.name]
            else []
          )
          ++ ["eDP-1"];
      }) [1 2 3 4 5 6 7 8 9];
    };

    gaming.enable = true;
  };

  home.packages = with pkgs; [
    kanshi
  ];

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "1920x1200";
            position = "0,0";
          }
        ];
      }
      {
        profile.name = "docked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "1920x1200";
            position = "3440,1560";
          }
          {
            criteria = secrets.monitors.lg.name;
            status = "enable";
            mode = "3440x1440";
            position = "0,1440";
          }
          {
            criteria = secrets.monitors.dell.name;
            status = "enable";
            mode = "2560x1440";
            position = "440,0";
          }
        ];
      }
      {
        profile.name = "parents";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "1920x1200";
            position = "0,80";
          }
          {
            criteria = secrets.monitors.parents.name;
            status = "enable";
            mode = "1280x1024";
            position = "1920,0";
            transform = "90";
          }
        ];
      }
    ];
  };
}
