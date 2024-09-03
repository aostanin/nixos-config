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
      description = "The root ZFS dataset.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r ${cfg.rootDatasetBlankSnapshot}
    '';

    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist" = {
      hideMounts = true;
      # ref: https://github.com/chayleaf/dotfiles/blob/master/system/modules/impermanence.nix
      directories =
        [
          "/var/lib/nixos"
          "/var/log"
        ]
        ++ lib.optional config.hardware.bluetooth.enable "/var/lib/bluetooth"
        ++ lib.optional config.networking.networkmanager.enable "/etc/NetworkManager/system-connections"
        ++ lib.optional config.services.tailscale.enable "/var/lib/tailscale"
        ++ lib.optional config.services.traefik.enable config.services.traefik.dataDir
        ++ lib.optional config.virtualisation.docker.enable "/var/lib/docker"
        ++ lib.optional config.virtualisation.podman.enable "/var/lib/containers"
        ++ lib.optionals config.virtualisation.libvirtd.enable [
          "/var/lib/libvirt"
          "/var/lib/libvirt/images"
        ]
        ++ (lib.mapAttrsToList (n: v: {
          directory = "/var/lib/private/gitea-runner/${n}";
        }) (lib.filterAttrs (n: v: v.enable) config.services.gitea-actions-runner.instances));
      files = [
        "/etc/adjtime"
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/private 0700 root root - -"
    ];
  };
}
