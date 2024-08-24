{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "home-assistant";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption "home" {port = 8123;};
    volumes = mkVolumesOption name {
      config = {};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        lan.enable = lib.mkDefault true;
        net.enable = lib.mkDefault true;
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        volumes = [
          "${cfg.volumes.config.path}:/config"
          "/etc/localtime:/etc/localtime:ro"
          "/run/dbus:/run/dbus:ro"
        ];
        extraOptions = [
          "--privileged"
          "--network=host"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    # TODO: Configure traefik instead?
    virtualisation.oci-containers.containers."${name}-forwarder" = lib.mkMerge [
      {
        image = "docker.io/alpine/socat:latest";
        dependsOn = [name];
        cmd = ["TCP-LISTEN:8123,fork,reuseaddr" "TCP:host.containers.internal:8123"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
