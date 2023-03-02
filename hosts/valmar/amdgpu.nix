{
  config,
  pkgs,
  ...
}: {
  hardware.opengl.extraPackages = with pkgs; [
    amdvlk
    rocm-opencl-icd
  ];

  services.xserver = {
    videoDrivers = ["amdgpu"];
    deviceSection = ''
      Option "TearFree" "true"
    '';
    xrandrHeads = [
      {
        output = "HDMI-A-0";
        primary = true;
        monitorConfig = ''
          Option "Position" "0 1440"
        '';
      }
      {
        output = "DVI-D-0";
        monitorConfig = ''
          Option "Position" "440 0"
        '';
      }
    ];
  };
}
