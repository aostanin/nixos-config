{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /btr_pool/_snapshots 0755 root root"
  ];

  services.btrbk.instances."local" = {
    onCalendar = "hourly";
    settings = {
      timestamp_format = "long";
      snapshot_preserve_min = "latest";
      snapshot_preserve = "48h 31d 26w";
      volume."/btr_pool" = {
        snapshot_dir = "_snapshots";
        subvolume."@" = {};
        subvolume."@home" = {};
      };
    };
  };

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/var/lib/bluetooth"
        "/var/lib/hass"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/traefik"
      ];
      timerConfig = null;
    };
  };

  systemd.services.restic-backups-remote.serviceConfig.ExecStartPost = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date -Iseconds > /var/lib/restic-last-backup'";
}
