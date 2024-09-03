{
  lib,
  config,
  ...
}: let
  name = "vaultwarden";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };
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
      raw.user = "${toString cfg.uid}:${toString cfg.gid}";
      raw.environment = {
        DOMAIN = "https://${lib.head (config.lib.containers.mkHosts "bitwarden")}";
        ROCKET_PORT = "8080";
        SIGNUPS_ALLOWED = "false";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.data = {
        destination = "/data";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      proxy = {
        enable = true;
        names = ["bitwarden"];
        port = 8080;
      };
    };
  };
}
