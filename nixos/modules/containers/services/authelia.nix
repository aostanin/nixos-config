{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "authelia";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption "auth" {};
    volumes = mkVolumesOption name {
      config = {
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
        net.enable = lib.mkDefault true;
      };
    };

    sops.secrets = {
      "containers/authelia/jwt_secret".owner = "container";
      "containers/authelia/session_secret".owner = "container";
      "containers/authelia/storage_encryption_key".owner = "container";
      "containers/authelia/notifier_smtp_password".owner = "container";
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/authelia/authelia:latest";
        environment = {
          PUID = uid;
          PGID = gid;
          AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "/run/secrets/jwt_secret";
          AUTHELIA_SESSION_SECRET_FILE = "/run/secrets/session_secret";
          AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "/run/secrets/storage_encryption_key";
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "/run/secrets/notifier_smtp_password";
        };
        ports = ["9091:9091"];
        volumes = [
          "${cfg.volumes.config.path}:/config"
          "/run/secrets/containers/authelia/jwt_secret:/run/secrets/jwt_secret:ro"
          "/run/secrets/containers/authelia/session_secret:/run/secrets/session_secret:ro"
          "/run/secrets/containers/authelia/storage_encryption_key:/run/secrets/storage_encryption_key:ro"
          "/run/secrets/containers/authelia/notifier_smtp_password:/run/secrets/notifier_smtp_password:ro"
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
