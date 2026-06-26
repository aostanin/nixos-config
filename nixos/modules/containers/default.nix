{
  config,
  lib,
  pkgs,
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

    # Trust the podman bridges so containers can reach host services (e.g. the
    # homeserver via its tailnet IP) through an enabled host firewall.
    networking.firewall.trustedInterfaces = ["podman+"];

    # A full-ruleset nftables reload flushes the inet netavark table, dropping
    # netavark's hostport-DNAT rules (published ports then only work until the
    # next container restart). Re-add them whenever nftables (re)starts OR its
    # ruleset changes (a deploy reloads — not restarts — nftables, so partOf
    # alone misses it; restartTriggers covers the reload-on-change case).
    systemd.services.podman-network-reload = lib.mkIf config.networking.nftables.enable {
      after = ["nftables.service" "podman.service"];
      partOf = ["nftables.service"];
      wantedBy = ["multi-user.target"];
      restartTriggers = [config.networking.nftables.ruleset];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe pkgs.podman} network reload --all";
      };
    };

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
