{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/raspberry-pi/3"
    ./klipper
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "octopi";
    useDHCP = true;
  };

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };
  };

  services = {
    moonraker = {
      enable = true;
      allowSystemControl = true;
      settings = {
        authorization = {
          force_logins = false;
          cors_domains = [
            "http://octopi"
          ];
          trusted_clients = [
            "127.0.0.0/8"
            "::1/128"
          ];
        };
        octoprint_compat = {};
      };
    };

    fluidd = {
      enable = true;
      nginx.locations."/webcam/".proxyPass = "http://127.0.0.1:8080/";
    };

    nginx.clientMaxBodySize = "100M";

    ustreamer = {
      enable = true;
      device = "/dev/v4l/by-id/usb-046d_C270_HD_WEBCAM_49407AC0-video-index0";
      extraArgs = [
        "--resolution=1280x720"
        "--desired-fps=30"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
