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

    uid = lib.mkOption {
      type = int;
      default = 500;
    };

    gid = lib.mkOption {
      type = int;
      default = 500;
    };

    storage = lib.mkOption {
      type = storageSubmodule;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      cloudflared.enable = true;

      docker = {
        enable = true;
        usePodman = true;
      };

      traefik.enable = true;
    };

    virtualisation.oci-containers.backend = "podman";

    users.users.container = {
      isSystemUser = true;
      uid = cfg.uid;
      group = "container";
    };

    users.groups.container = {
      gid = cfg.gid;
    };
  };
}
