{
  lib,
  config,
  secrets,
  ...
}: let
  name = "neko";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    screen = lib.mkOption {
      type = lib.types.str;
      default = "1920x1080@30";
      description = "Desktop resolution and refresh rate.";
    };

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Devices to pass through (Intel GPU render nodes for VAAPI).";
    };

    webrtc = {
      epr = lib.mkOption {
        type = lib.types.str;
        default = "52000-52100";
        description = "WebRTC ephemeral UDP port range (host == container).";
      };

      nat1to1 = lib.mkOption {
        type = lib.types.str;
        default = secrets.network.tailscale.hosts.${config.networking.hostName}.address;
        description = ''
          IP advertised in WebRTC ICE candidates. Defaults to the host's
          Tailscale IP so clients reach the stream over the tailnet.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/${name}/user_password" = {};
      "containers/${name}/admin_password" = {};
    };

    sops.templates."${name}.env".content = ''
      NEKO_MEMBER_MULTIUSER_USER_PASSWORD=${config.sops.placeholder."containers/${name}/user_password"}
      NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD=${config.sops.placeholder."containers/${name}/admin_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/m1k1o/neko/intel-firefox:latest";
      raw.ports = ["${cfg.webrtc.epr}:${cfg.webrtc.epr}/udp"];
      raw.environment = {
        NEKO_DESKTOP_SCREEN = cfg.screen;
        NEKO_WEBRTC_EPR = cfg.webrtc.epr;
        NEKO_WEBRTC_ICELITE = "1";
        NEKO_WEBRTC_NAT1TO1 = cfg.webrtc.nat1to1;
        # libva auto-detect (vaGetDriverNames) fails in-container; force iHD.
        LIBVA_DRIVER_NAME = "iHD";
        # This iGPU has no VP8 encode entrypoint (only H264/VP9), so the
        # default vp8 codec builds a vaapivp8enc pipeline that never starts.
        # Quirk (m1k1o/neko#610, verified): codec alone is ignored — neko only
        # honours it when the plural pipelines/ids are also set. neko discards
        # the pipeline content below and builds its own vaapih264enc pipeline;
        # the block just has to be present, non-empty, and reference id "main".
        NEKO_CAPTURE_VIDEO_CODEC = "h264";
        NEKO_CAPTURE_VIDEO_IDS = "main";
        NEKO_CAPTURE_VIDEO_PIPELINES = builtins.toJSON {
          main.gst_pipeline =
            "ximagesrc display-name=:99.0 show-pointer=false use-damage=false"
            + " ! video/x-raw,framerate=25/1 ! videoconvert ! queue"
            + " ! video/x-raw,format=NV12"
            + " ! vaapih264enc rate-control=cbr bitrate=8000 keyframe-period=180"
            + " ! h264parse config-interval=-1 ! video/x-h264,stream-format=byte-stream"
            + " ! appsink name=appsink";
        };
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.extraOptions =
        ["--shm-size=2gb"]
        ++ lib.map (d: "--device=${d}") cfg.devices;
      volumes.firefox = {
        destination = "/home/neko/.mozilla/firefox";
        user = "1000";
        group = "1000";
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
