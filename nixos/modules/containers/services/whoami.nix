{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "whoami";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    proxy = mkProxyOption name {};
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name}.proxy = {
      enable = lib.mkDefault true;
      tailscale.enable = lib.mkDefault true;
      lan.enable = lib.mkDefault true;
      net.enable = lib.mkDefault true;
      net.auth = lib.mkDefault "authelia";
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/traefik/whoami";
        # labels =
        #   # For autoupdate
        #   "io.containers.autoupdate" = "registry";
        # };
      }
      (mkContainerProxyConfig name cfg.proxy)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;
  };
}
