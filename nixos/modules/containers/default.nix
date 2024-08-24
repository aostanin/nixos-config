{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.containers;
in {
  imports = [
    ./networks.nix
    ./services
  ];

  options.localModules.containers = let
    storageSubmodule = lib.types.submodule {
      options = {
        default = lib.mkOption {
          type = lib.types.str;
          description = ''
            Default storage path.
          '';
        };

        bulk = lib.mkOption {
          type = lib.types.str;
          description = ''
            Default bulk storage path.
          '';
        };
      };
    };
  in {
    enable = lib.mkEnableOption "containers";

    host = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = ''
        Host name.
      '';
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = secrets.domain;
      description = ''
        Domain name.
      '';
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
  };
}
