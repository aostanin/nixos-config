{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  name = "matrix";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enableFacebookBridge = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Facebook Messenger bridge.";
    };

    enableInstagramBridge = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Instagram bridge.";
    };

    enableTelegramBridge = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Telegram bridge.";
    };

    enableWhatsAppBridge = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the WhatsApp bridge.";
    };

    enableSkypeBridge = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Skype bridge.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/${name}/postgres_password" = {};
      "forgejo/registry_token" = {};
    };

    sops.templates."synapse-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
    '';

    localModules.containers.containers.synapse = {
      raw.image = "docker.io/matrixdotorg/synapse:latest";
      networks = [name];
      raw.dependsOn = ["synapse-db"];
      volumes = {
        data = {
          name = "synapse";
          parent = name;
          destination = "/data";
        };
        media = {
          storageType = "bulk";
          parent = name;
          destination = "/data/media_store";
        };
      };
      raw.volumes = let
        sharedSecretAuthenticator = pkgs.fetchFromGitHub {
          owner = "devture";
          repo = "matrix-synapse-shared-secret-auth";
          rev = "2.0.3";
          sha256 = "sha256-ZMEUBC2Y4J1+4tHfsMxqzTO/P1ef3aB81OAhEs+Tdc4=";
        };
      in ["${sharedSecretAuthenticator}/shared_secret_authenticator.py:/usr/local/lib/python3.11/site-packages/shared_secret_authenticator.py:ro"];
      proxy = {
        enable = true;
        names = ["matrix"];
        port = 8008;
        default.enable = true;
      };
    };

    localModules.containers.containers.synapse-db = {
      raw.image = "docker.io/library/postgres:11-alpine";
      networks = [name];
      raw.environmentFiles = [config.sops.templates."synapse-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
    };

    localModules.containers.containers.mautrix-meta-facebook = lib.mkIf cfg.enableFacebookBridge {
      raw.image = "dock.mau.dev/mautrix/meta:latest";
      networks = [name];
      raw.dependsOn = ["synapse"];
      volumes.data = {
        name = "synapse/mautrix-meta-facebook";
        parent = name;
        destination = "/data";
      };
    };

    localModules.containers.containers.mautrix-meta-instagram = lib.mkIf cfg.enableInstagramBridge {
      raw.image = "dock.mau.dev/mautrix/meta:latest";
      networks = [name];
      raw.dependsOn = ["synapse"];
      volumes.data = {
        name = "synapse/mautrix-meta-instagram";
        parent = name;
        destination = "/data";
      };
    };

    localModules.containers.containers.mautrix-telegram = lib.mkIf cfg.enableTelegramBridge {
      raw.image = "dock.mau.dev/mautrix/telegram:latest";
      networks = [name];
      raw.dependsOn = ["synapse"];
      volumes.data = {
        name = "synapse/mautrix-telegram";
        parent = name;
        destination = "/data";
      };
    };

    localModules.containers.containers.mautrix-whatsapp = lib.mkIf cfg.enableWhatsAppBridge {
      raw.image = "dock.mau.dev/mautrix/whatsapp:latest";
      networks = [name];
      raw.dependsOn = ["synapse"];
      volumes.data = {
        name = "synapse/mautrix-whatsapp";
        parent = name;
        destination = "/data";
      };
    };

    localModules.containers.containers.go-skype-bridge = lib.mkIf cfg.enableSkypeBridge {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/go-skype-bridge:latest";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      networks = [name];
      raw.dependsOn = ["synapse"];
      volumes.data = {
        name = "synapse/go-skype-bridge";
        parent = name;
        destination = "/data";
      };
    };
  };
}
