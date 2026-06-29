{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.impermanence;
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
        (container images, model files, caches). Not backed up.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd.services.rollback = let
      pool = lib.head (lib.splitString "/" cfg.rootDatasetBlankSnapshot);
    in {
      description = "Rollback ZFS root to blank snapshot";
      wantedBy = ["initrd.target"];
      requires = ["zfs-import-${pool}.service"];
      after = ["zfs-import-${pool}.service"];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      script = "zfs rollback -r ${cfg.rootDatasetBlankSnapshot}";
    };

    fileSystems = {
      ${cfg.safeRoot}.neededForBoot = true;
      ${cfg.cacheRoot}.neededForBoot = true;
    };

    environment.persistence = {
      ${cfg.safeRoot} = {
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
      ${cfg.cacheRoot} = {
        hideMounts = true;
        directories =
          [
            "/var/log"
          ]
          ++ lib.optional config.virtualisation.docker.enable "/var/lib/docker"
          ++ lib.optional config.virtualisation.podman.enable "/var/lib/containers"
          ++ lib.optional config.services.dnsmasq.enable "/var/lib/dnsmasq"
          ++ lib.optional config.services.chrony.enable "/var/lib/chrony"
          ++ lib.optional config.services.adguardhome.enable "/var/lib/private/AdGuardHome"
          ++ lib.optional (lib.any (v: v.enable) (lib.attrValues config.services.gitea-actions-runner.instances))
          "/var/lib/private/gitea-runner"
          ++ map (n: "/var/cache/restic-backups-${n}") (lib.attrNames config.services.restic.backups);
        files = [
          "/etc/adjtime"
        ];
      };
    };

    # systemd DynamicUser StateDirectory needs /var/lib/private at 0700, but
    # impermanence creates the bind-mount parent by copying the persistent
    # source's mode (default 0755) — impermanence#254. For every persist root
    # (from any module) that holds a /var/lib/private/* entry, pin its source to
    # 0700 so that mode propagates to the mount-point parent on activation.
    systemd.tmpfiles.rules = lib.unique (lib.concatLists (lib.mapAttrsToList (
        root: persist:
          lib.optionals
          (lib.any (d:
            lib.hasPrefix "/var/lib/private/" (
              if builtins.isString d
              then d
              else d.directory
            ))
          persist.directories)
          [
            "d /var/lib/private 0700 root root - -"
            "d ${root}/var/lib/private 0700 root root - -"
          ]
      )
      config.environment.persistence));
  };
}
