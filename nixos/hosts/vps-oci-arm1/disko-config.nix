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
          acltype = "posix";
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
            options.mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/local/root@blank";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "/nix";
          };

          persist = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "persist/safe" = {
            type = "zfs_fs";
            mountpoint = "/persist/safe";
            options.mountpoint = "/persist/safe";
          };
          "persist/cache" = {
            type = "zfs_fs";
            mountpoint = "/persist/cache";
            options = {
              mountpoint = "/persist/cache";
              sync = "disabled";
            };
          };
          "persist/home" = {
            type = "zfs_fs";
            options.mountpoint = "/home";
          };
        };
      };
    };
  };
}
