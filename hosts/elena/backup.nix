{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  services.rsync-backup = {
    enable = true;
    backups = {
      vps-gce1 = {
        source = "root@${secrets.network.zerotier.hosts.vps-gce1.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-gce1";
      };
      vps-oci1 = {
        source = "root@${secrets.network.zerotier.hosts.vps-oci1.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-oci1";
      };
      vps-oci2 = {
        source = "root@${secrets.network.zerotier.hosts.vps-oci2.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-oci2";
      };
    };
  };

  services.zrepl = {
    enable = true;
    settings = {
      jobs = [
        {
          name = "snap-frequent";
          type = "snap";
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/appdata/temp<" = false;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
            "vmpool/virtualization<" = true;
          };
          snapshotting = {
            type = "periodic";
            interval = "15m";
            prefix = "zrepl_";
            timestamp_format = "iso-8601";
          };
          pruning = {
            keep = [
              {
                type = "grid";
                grid = "1x1h(keep=all) | 24x1h | 14x1d";
                regex = "^zrepl_.*";
              }
              {
                type = "regex";
                negate = true;
                regex = "^zrepl_.*";
              }
            ];
          };
        }
        {
          name = "snap-infrequent";
          type = "snap";
          filesystems = {
            "tank/backup<" = true;
            "tank/backup/hosts/zfs<" = false;
            "tank/download<" = true;
            "tank/media<" = true;
            "tank/personal<" = true;
            "tank/virtualization<" = true;
          };
          snapshotting = {
            type = "periodic";
            interval = "12h";
            prefix = "zrepl_";
            timestamp_format = "iso-8601";
          };
          pruning = {
            keep = [
              {
                type = "grid";
                grid = "1x1h(keep=all) | 24x1h | 14x1d";
                regex = "^zrepl_.*";
              }
              {
                type = "regex";
                negate = true;
                regex = "^zrepl_.*";
              }
            ];
          };
        }
        {
          type = "sink";
          name = "sink";
          serve = {
            type = "tcp";
            listen = ":8888";
            listen_freebind = true;
            clients = {
              "${secrets.network.zerotier.hosts.roan.address}" = "roan";
              "${secrets.network.zerotier.hosts.mareg.address}" = "mareg";
              "${secrets.network.zerotier.hosts.valmar.address}" = "valmar";
              "${secrets.network.storage.hosts.valmar.address}" = "valmar";
            };
          };
          recv = {
            placeholder.encryption = "inherit";
          };
          root_fs = "tank/backup/hosts/zfs";
        }
        {
          type = "source";
          name = "source";
          serve = {
            type = "tcp";
            listen = "${secrets.network.storage.hosts.elena.address}:8889";
            clients = {
              "${secrets.network.storage.hosts.valmar.address}" = "valmar";
            };
          };
          send.encrypted = false;
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/appdata/temp<" = false;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/root/nix<" = false;
            "tank/media/audiobooks<" = true;
            "tank/media/books<" = true;
            "tank/media/music<" = true;
            "tank/personal<" = true;
          };
          snapshotting.type = "manual";
        }
      ];
    };
  };
}
