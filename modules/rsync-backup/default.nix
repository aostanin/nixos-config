{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.rsync-backup;

  backupSubmodule = types.submodule {
    options = {
      source = mkOption {
        type = types.str;
        example = "root@machine:/storage/appdata";
        description = ''
          Backup source.
        '';
      };

      destination = mkOption {
        type = types.str;
        example = "/storage/backup";
        description = ''
          Backup destination.
        '';
      };
    };
  };
in {
  options.services.rsync-backup = {
    enable = mkEnableOption "rsync-backup";

    backups = mkOption {
      type = types.attrsOf backupSubmodule;
      description = ''
        Backups definition.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.timers = mkMerge (mapAttrsToList (name: backup: {
        "rsync-backup-${name}" = {
          wantedBy = ["timers.target"];
          partOf = ["rsync-backup-${name}.service"];
          timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "60m";
          };
        };
      })
      cfg.backups);

    systemd.services = mkMerge (mapAttrsToList (name: backup: {
        "rsync-backup-${name}" = {
          description = "rsync backup for ${name}";
          path = [pkgs.openssh];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = let
              script = pkgs.writeScriptBin "rsync-backup-${name}" ''
                #!${pkgs.stdenv.shell}
                set -e
                ${pkgs.rsync}/bin/rsync \
                  --verbose \
                  --stats \
                  --archive \
                  --delete \
                  --numeric-ids \
                  --hard-links \
                  --acls \
                  --xattrs \
                  --relative \
                  --compress --compress-choice=lz4 \
                  "${backup.source}" \
                  "${backup.destination}"
              '';
            in "${script}/bin/rsync-backup-${name}";
          };
        };
      })
      cfg.backups);
  };
}
