{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "vaultwarden";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption "bitwarden" {port = 8080;};
    volumes = mkVolumesOption name {
      data = {
        user = uid;
        group = gid;
      };
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        lan.enable = lib.mkDefault true;
      };
    };

    sops.secrets = {
      "containers/vaultwarden/yubico_client_id" = {};
      "containers/vaultwarden/yubico_secret_key" = {};
    };

    sops.templates."${name}.env".content = ''
      YUBICO_CLIENT_ID=${config.sops.placeholder."containers/vaultwarden/yubico_client_id"}
      YUBICO_SECRET_KEY=${config.sops.placeholder."containers/vaultwarden/yubico_secret_key"}
    '';

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/vaultwarden/server:latest";
        user = "${uid}:${gid}";
        environment = {
          DOMAIN = "https://${lib.head cfg.proxy.hosts}";
          ROCKET_PORT = "8080";
          SIGNUPS_ALLOWED = "false";
        };
        environmentFiles = [config.sops.templates."${name}.env".path];
        volumes = [
          "${cfg.volumes.data.path}:/data"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
