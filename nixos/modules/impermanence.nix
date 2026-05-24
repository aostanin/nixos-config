{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.impermanence;

  safe = {
    hideMounts = true;
    directories =
      [
        "/var/lib/nixos"
      ]
      ++ lib.optional config.hardware.bluetooth.enable "/var/lib/bluetooth"
      ++ lib.optional config.networking.networkmanager.enable "/etc/NetworkManager/system-connections"
      ++ lib.optional config.services.tailscale.enable "/var/lib/tailscale"
      ++ lib.optional config.services.traefik.enable config.services.traefik.dataDir
      ++ lib.optionals config.virtualisation.libvirtd.enable [
        "/var/lib/libvirt"
        "/var/lib/libvirt/images"
      ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  cache = {
    hideMounts = true;
    directories =
      [
        "/var/log"
      ]
      ++ lib.optional config.virtualisation.docker.enable "/var/lib/docker"
      ++ lib.optional config.virtualisation.podman.enable "/var/lib/containers"
      ++ lib.optional (lib.any (v: v.enable) (lib.attrValues config.services.gitea-actions-runner.instances))
      "/var/lib/private/gitea-runner";
    files = [
      "/etc/adjtime"
    ];
  };

  merged = {
    hideMounts = true;
    directories = safe.directories ++ cache.directories;
    files = safe.files ++ cache.files;
  };

  flat = cfg.safeRoot == cfg.cacheRoot;
in {
  options.localModules.impermanence = {
    enable = lib.mkEnableOption "impermanence";

    rootDatasetBlankSnapshot = lib.mkOption {
      type = lib.types.str;
      default = "rpool/local/root@blank";
      description = "The root ZFS dataset blank snapshot to roll back to on boot.";
    };

    safeRoot = lib.mkOption {
      type = lib.types.str;
      default = "/persist/safe";
      description = "Persist root for data that cannot be recreated. Expected to be snapshotted and backed up.";
    };

    cacheRoot = lib.mkOption {
      type = lib.types.str;
      default = "/persist/cache";
      description = ''
        Persist root for recreatable data kept across reboots only for performance
        (container images, model files, caches). Not backed up. May equal safeRoot
        for hosts that keep a single flat persist dataset.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.postResumeCommands = lib.mkAfter ''
      zfs rollback -r ${cfg.rootDatasetBlankSnapshot}
    '';

    fileSystems =
      {${cfg.safeRoot}.neededForBoot = true;}
      // {${cfg.cacheRoot}.neededForBoot = true;};

    environment.persistence =
      if flat
      then {${cfg.safeRoot} = merged;}
      else {
        ${cfg.safeRoot} = safe;
        ${cfg.cacheRoot} = cache;
      };

    systemd.tmpfiles.rules = [
      "d /var/lib/private 0700 root root - -"
    ];
  };
}
