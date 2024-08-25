{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "frigate";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 8971;};
    volumes = mkVolumesOption name {
      config = {};
      media = {storageType = "bulk";};
    };

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Extra devices to bind to the container.
      '';
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
    };

    sops.secrets = {
      "containers/frigate/rtsp_password" = {};
    };

    sops.templates."${name}.env".content = ''
      FRIGATE_RTSP_PASSWORD=${config.sops.placeholder."containers/frigate/rtsp_password"}
    '';

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        ports = [
          "127.0.0.1:5000:5000" # API
          "1935:1935" # RTMP
          "8554:8554" # RTSP feeds
          "8555:8555/tcp" # WebRTC over tcp
          "8555:8555/udp" # WebRTC over udp
        ];
        environmentFiles = [config.sops.templates."${name}.env".path];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${cfg.volumes.config.path}:/config"
          "${cfg.volumes.media.path}:/media/frigate"
        ];
        extraOptions =
          [
            "--privileged" # For Intel GPU usage
            "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
          ]
          ++ lib.map (d: "--device=${d}") cfg.devices;
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
