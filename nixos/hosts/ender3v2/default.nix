{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./klipper
    ./hardware-configuration.nix
  ];

  hardware.raspberry-pi.config.pi3 = {
    # camera-streamer's hardware MJPEG decode + H.264 encode.
    options.gpu_mem = {
      enable = true;
      value = 128;
    };
    # dwc_otg, the vendor default, causes serial retransmits to the printer on
    # arm64, where its FIQ is only simulated.
    dt-overlays.dwc2 = {
      enable = true;
      params.dr_mode = {
        enable = true;
        value = "host";
      };
    };
  };

  networking = {
    hostName = "ender3v2";
    useDHCP = true;
  };

  localModules = {
    traefik.enable = true;

    ingress.ender3v2.port = 8081;

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
        "webcam printer" = {
          service = "webrtc-camerastreamer";
          stream_url = "/webcam/webrtc";
          snapshot_url = "/webcam/snapshot";
          aspect_ratio = "16:9";
          target_fps = 30;
        };
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

    # The C270 defaults to 60 Hz anti-flicker; mains here is 50 Hz.
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="0825", ATTR{index}=="0", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d $devnode --set-ctrl=power_line_frequency=1"
    '';
  };

  # Hardware H.264 over WebRTC keeps remote viewing light: the Pi 3's single
  # USB bus also carries Ethernet and the printer's serial link.
  systemd.services.camera-streamer = {
    description = "camera-streamer for the C270";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        (lib.getExe (pkgs.unstable.camera-streamer.overrideAttrs (old: {
          patches = (old.patches or []) ++ [./camera-streamer-skip-incomplete-jpeg.patch];
        })))
        "--camera-path=/dev/v4l/by-id/usb-046d_C270_HD_WEBCAM_49407AC0-video-index0"
        "--camera-format=JPEG"
        "--camera-width=1280"
        "--camera-height=720"
        "--camera-fps=30"
        "--camera-nbufs=3"
        "--camera-snapshot.height=720"
        "--camera-stream.height=720"
        "--camera-video.height=720"
        "--camera-video.options=video_bitrate_mode=0;video_bitrate=4000000;repeat_sequence_header=5000000;h264_i_frame_period=30;h264_level=4;h264_profile=high;h264_minimum_qp_value=16;h264_maximum_qp_value=32"
        "--http-listen=127.0.0.1"
        "--http-port=8080"
      ];
      DynamicUser = true;
      SupplementaryGroups = ["video"];
      Restart = "always";
      RestartSec = 10;
      # As in upstream's example service.
      Nice = 10;
      IOSchedulingClass = "idle";
      CPUWeight = 20;
      AllowedCPUs = "1-2";
      MemoryMax = "250M";
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
