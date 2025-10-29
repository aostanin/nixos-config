{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
              };
            };
            rpool = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          atime = "off";
          compression = "zstd";
          normalization = "formD";
          dnodesize = "auto";
          xattr = "sa";
          acltype = "posixacl";
        };
        options = {
          ashift = "12";
          autoexpand = "on";
        };

        datasets = {
          local = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              sync = "disabled";
            };
          };
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/local/root@blank";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };

          persist = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "persist/safe" = {
            type = "zfs_fs";
            mountpoint = "/persist/safe";
            options = {
              "com.sun:auto-snapshot" = "true";
              "com.sun:auto-snapshot:frequent" = "true";
              "com.sun:auto-snapshot:hourly" = "true";
              "com.sun:auto-snapshot:daily" = "true";
              "com.sun:auto-snapshot:weekly" = "true";
              "com.sun:auto-snapshot:monthly" = "false";
            };
          };
          "persist/cache" = {
            type = "zfs_fs";
            mountpoint = "/persist/cache";
            options = {
              sync = "disabled";
              "com.sun:auto-snapshot" = "true";
              "com.sun:auto-snapshot:frequent" = "false";
              "com.sun:auto-snapshot:hourly" = "false";
              "com.sun:auto-snapshot:daily" = "true";
              "com.sun:auto-snapshot:weekly" = "false";
              "com.sun:auto-snapshot:monthly" = "false";
            };
          };
          "persist/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              "com.sun:auto-snapshot" = "true";
              "com.sun:auto-snapshot:frequent" = "true";
              "com.sun:auto-snapshot:hourly" = "true";
              "com.sun:auto-snapshot:daily" = "true";
              "com.sun:auto-snapshot:weekly" = "true";
              "com.sun:auto-snapshot:monthly" = "false";
            };
          };
        };
      };
    };
  };
}
