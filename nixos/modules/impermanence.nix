{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.impermanence;
in {
  options.localModules.impermanence = {
    enable = lib.mkEnableOption "impermanence";

    rootDataset = lib.mkOption {
      type = lib.types.str;
      default = "rpool/local/root";
      description = ''
        The root ZFS dataset.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r ${cfg.rootDataset}@blank
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
        ++ lib.optionals config.hardware.bluetooth.enable [
          "/var/lib/bluetooth"
        ]
        ++ lib.optionals config.networking.networkmanager.enable [
          "/etc/NetworkManager/system-connections"
        ]
        ++ lib.optionals config.services.tailscale.enable [
          "/var/lib/tailscale"
        ]
        ++ lib.optionals config.services.traefik.enable [
          config.services.traefik.dataDir
        ]
        ++ lib.optionals config.virtualisation.docker.enable [
          "/var/lib/docker"
        ]
        ++ lib.optionals config.virtualisation.podman.enable [
          "/var/lib/containers"
        ]
        ++ lib.optionals config.virtualisation.libvirtd.enable [
          "/var/lib/libvirt"
          "/var/lib/libvirt/images"
        ];
      files = [
        "/etc/adjtime"
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
