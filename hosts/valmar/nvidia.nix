{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    videoDrivers = ["nvidia"];
    # TODO: Doesn't work with nvidia? https://github.com/NixOS/nixpkgs/issues/30796#issuecomment-615680290
    xrandrHeads = [
      {
        output = "HDMI-0";
        primary = true;
        monitorConfig = ''
          Option "Position" "0 1440"
        '';
      }
      {
        output = "DP-0";
        monitorConfig = ''
          Option "Position" "440 0"
        '';
      }
    ];
  };
}
