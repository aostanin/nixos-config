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
    traefik.enable = true;

    ingress.fluidd.port = 8081;

    common = {
      enable = true;
      minimal = true;
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };

    moonraker = {
      enable = true;
      allowSystemControl = true;
      settings = {
        authorization = {
          force_logins = false;
          trusted_clients = [
            "0.0.0.0/0"
            "::/0"
          ];
          cors_domains = ["*"];
        };
        octoprint_compat = {};
      };
    };

    fluidd = {
      enable = true;
      nginx = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8081;
          }
        ];
        locations."/webcam/".proxyPass = "http://127.0.0.1:8080/";
      };
    };

    nginx.clientMaxBodySize = "100M";

    ustreamer = {
      # TODO: Unstable
      # enable = true;
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

  hardware.deviceTree = {
    filter = "bcm2837-rpi-*.dtb";
    overlays = [
      # dwc2 is more stable, except for usb webcam..
      {
        name = "dwc2-overlay";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "brcm,bcm2837";

            fragment@0 {
              target = <&usb>;
              #address-cells = <0x01>;
              #size-cells = <0x01>;

              __overlay__ {
                compatible = "brcm,bcm2835-usb";
                dr_mode = "host";
                g-np-tx-fifo-size = <0x20>;
                g-rx-fifo-size = <0x22e>;
                g-tx-fifo-size = <0x200 0x200 0x200 0x200 0x200 0x100 0x100>;
                status = "okay";
                phandle = <0x01>;
              };
            };
          };
        '';
      }
    ];
  };
}
