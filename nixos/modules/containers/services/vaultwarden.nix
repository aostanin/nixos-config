{
  lib,
  config,
  ...
}: let
  name = "vaultwarden";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/vaultwarden/yubico_client_id" = {};
      "containers/vaultwarden/yubico_secret_key" = {};
    };

    sops.templates."${name}.env".content = ''
      YUBICO_CLIENT_ID=${config.sops.placeholder."containers/vaultwarden/yubico_client_id"}
      YUBICO_SECRET_KEY=${config.sops.placeholder."containers/vaultwarden/yubico_secret_key"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/vaultwarden/server:latest";
      raw.user = "${uid}:${gid}";
      raw.environment = {
        DOMAIN = "https://${lib.head (config.lib.containers.mkHosts "bitwarden")}";
        ROCKET_PORT = "8080";
        SIGNUPS_ALLOWED = "false";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.data = {
        destination = "/data";
        user = uid;
        group = gid;
      };
      proxy = {
        enable = true;
        names = ["bitwarden"];
        port = 8080;
      };
    };
  };
}
