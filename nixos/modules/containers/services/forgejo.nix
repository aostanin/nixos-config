{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "forgejo";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 3000;};
    volumes = mkVolumesOption name {
      data = {
        user = uid;
        group = gid;
      };
    };
  };

  config = let
    hosts = mkDefaultHosts name {};
    gitHosts = mkDefaultHosts "git" {};
  in
    lib.mkIf (config.localModules.containers.enable && cfg.enable) {
      localModules.containers.services.${name} = {
        autoupdate = lib.mkDefault true;
        proxy = {
          enable = lib.mkDefault true;
          hosts = hosts ++ gitHosts;
          tailscale.enable = lib.mkDefault true;
        };
      };

      localModules.containers.networks.${name} = {};

      virtualisation.oci-containers.containers.${name} = lib.mkMerge [
        {
          image = "codeberg.org/forgejo/forgejo:8";
          ports = ["2222:22"];
          environment = rec {
            USER_UID = uid;
            USER_GID = gid;
            GITEA__SERVER__DOMAIN = lib.head hosts;
            GITEA__SERVER__SSH_DOMAIN = lib.head gitHosts;
            GITEA__SERVER__ROOT_URL = "https://${GITEA__SERVER__DOMAIN}/";
          };
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
