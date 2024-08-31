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
          sync = "disabled";
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
            options.canmount = "off";
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
          "local/containers" = {
            type = "zfs_fs";
            mountpoint = "/persist/var/lib/containers";
          };

          system = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "system/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
          };
          "system/images" = {
            type = "zfs_fs";
            mountpoint = "/persist/var/lib/libvirt/images";
            options.recordsize = "64K";
          };
          "system/appdata" = {
            type = "zfs_fs";
            mountpoint = "/persist/storage/appdata";
          };

          user = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "user/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            postCreateHook = "zfs snapshot rpool/user/home@blank";
          };
        };
      };
    };
  };
}
