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
          root = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "root/nixos" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "root/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };

          home = {
            type = "zfs_fs";
            mountpoint = "/home";
          };

          appdata = {
            type = "zfs_fs";
            mountpoint = "/storage/appdata";
            options.canmount = "off";
          };
          "appdata/docker" = {
            type = "zfs_fs";
          };
          "appdata/libvirt" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt";
          };

          virtualization = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "virtualization/docker" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/docker";
          };
          "virtualization/images" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt/images";
            options = {
              canmount = "off";
              recordsize = "64K";
            };
          };
        };
      };
    };
  };
}
