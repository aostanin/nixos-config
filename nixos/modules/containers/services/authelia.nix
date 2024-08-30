{
  lib,
  config,
  ...
}: let
  name = "authelia";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/authelia/jwt_secret".owner = "container";
      "containers/authelia/session_secret".owner = "container";
      "containers/authelia/storage_encryption_key".owner = "container";
      "containers/authelia/notifier_smtp_password".owner = "container";
    };

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/authelia/authelia:latest";
      raw.environment = {
        PUID = uid;
        PGID = gid;
        AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "/run/secrets/jwt_secret";
        AUTHELIA_SESSION_SECRET_FILE = "/run/secrets/session_secret";
        AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "/run/secrets/storage_encryption_key";
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "/run/secrets/notifier_smtp_password";
      };
      raw.ports = ["9091:9091"];
      volumes.config = {
        destination = "/config";
        user = uid;
        group = gid;
      };
      raw.volumes = [
        "/run/secrets/containers/authelia/jwt_secret:/run/secrets/jwt_secret:ro"
        "/run/secrets/containers/authelia/session_secret:/run/secrets/session_secret:ro"
        "/run/secrets/containers/authelia/storage_encryption_key:/run/secrets/storage_encryption_key:ro"
        "/run/secrets/containers/authelia/notifier_smtp_password:/run/secrets/notifier_smtp_password:ro"
      ];
      proxy = {
        enable = true;
        names = ["auth"];
        default.enable = true;
      };
    };
  };
}
