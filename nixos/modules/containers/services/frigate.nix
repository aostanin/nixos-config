{
  lib,
  config,
  ...
}: let
  name = "frigate";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Extra devices to bind to the container.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/frigate/rtsp_password" = {};
    };

    sops.templates."${name}.env".content = ''
      FRIGATE_RTSP_PASSWORD=${config.sops.placeholder."containers/frigate/rtsp_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/blakeblackshear/frigate:stable";
      raw.ports = [
        "127.0.0.1:5000:5000" # API
        "1935:1935" # RTMP
        "8554:8554" # RTSP feeds
        "8555:8555/tcp" # WebRTC over tcp
        "8555:8555/udp" # WebRTC over udp
      ];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes = {
        config.destination = "/config";
        media = {
          storageType = "bulk";
          destination = "/media/frigate";
        };
      };
      raw.volumes = ["/etc/localtime:/etc/localtime:ro"];
      raw.extraOptions =
        [
          "--privileged" # For Intel GPU usage
          "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        ]
        ++ lib.map (d: "--device=${d}") cfg.devices;
      proxy = {
        enable = true;
        port = 8971;
      };
    };
  };
}
