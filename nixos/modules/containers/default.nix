{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.containers;
in {
  imports = [
    ./containers.nix
    ./networks.nix
    ./services
  ];

  options.localModules.containers = with lib.types; let
    storageSubmodule = lib.types.submodule {
      options = {
        default = lib.mkOption {
          type = str;
          description = ''
            Default storage path.
          '';
        };

        bulk = lib.mkOption {
          type = str;
          description = ''
            Default bulk storage path.
          '';
        };

        temp = lib.mkOption {
          type = str;
          description = ''
            Default temp storage path.
          '';
        };
      };
    };
  in {
    enable = lib.mkEnableOption "containers";

    host = lib.mkOption {
      type = str;
      default = config.networking.hostName;
      description = ''
        Host name.
      '';
    };

    domain = lib.mkOption {
      type = str;
      default = secrets.domain;
      description = ''
        Domain name.
      '';
    };

    createUser = lib.mkOption {
      type = bool;
      default = true;
    };

    uid = lib.mkOption {
      type = int;
      default = 500;
      description = "Default uid for containers running as a user.";
    };

    gid = lib.mkOption {
      type = int;
      default = 500;
      description = "Default gid for containers running as a user.";
    };

    storage = lib.mkOption {
      type = storageSubmodule;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      cloudflared.enable = let
        allProxies = lib.flatten (lib.map (v: lib.attrValues v.proxies) (lib.attrValues config.localModules.containers.containers));
        defaultNetworkAccessEnabled = lib.any (v: v.default.enable) allProxies;
      in
        lib.mkDefault defaultNetworkAccessEnabled;

      podman.enable = true;

      traefik.enable = true;
    };

    virtualisation.oci-containers.backend = "podman";

    users.users.container = lib.mkIf cfg.createUser {
      isSystemUser = true;
      uid = cfg.uid;
      group = "container";
    };

    users.groups.container = lib.mkIf cfg.createUser {
      gid = cfg.gid;
    };
  };
}
