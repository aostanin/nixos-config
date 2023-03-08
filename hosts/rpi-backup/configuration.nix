{
  config,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
  drives = [
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG052SA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TT6A"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TTLA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TV0A"
  ];
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/zerotier
    ../../modules
  ];

  boot = {
    supportedFilesystems = ["zfs"];
  };

  networking = {
    hostName = "rpi-backup";
    hostId = "9d6a993f";
    interfaces.eth0.useDHCP = true;
  };

  services.zrepl = {
    enable = true;
    settings = {
      jobs = [
        {
          type = "pull";
          name = "pull-elena";
          connect = {
            type = "tcp";
            address = "${secrets.network.zerotier.hosts.elena.address}:8889";
          };
          recv = {
            placeholder.encryption = "inherit";
          };
          root_fs = "backup/backup/hosts/zfs/elena";
          interval = "manual";
          pruning = {
            keep_sender = [
              {
                type = "regex";
                regex = ".*";
              }
            ];
            keep_receiver = [
              {
                type = "grid";
                grid = "1x1h(keep=all) | 24x1h | 90x1d";
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
      ];
    };
  };
}
