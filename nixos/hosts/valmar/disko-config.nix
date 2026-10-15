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
                mountOptions = ["umask=0077"];
              };
            };
            swap = {
              size = "32G";
              content = {
                type = "swap";
                randomEncryption = true;
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
      vm = {
        type = "disk";
        content = {
          type = "gpt";
          partitions.vmpool = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "vmpool";
            };
          };
        };
      };
    };
    zpool = {
      vmpool = {
        type = "zpool";
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          atime = "off";
          compression = "zstd";
          dnodesize = "auto";
          xattr = "sa";
          acltype = "posix";
        };
        options.ashift = "12";

        # Outside any impermanence bind: zfs-mount.service isn't ordered against
        # them. With 26.11's zfs-mount-generator support (nixpkgs#517731) this
        # can mount under /var/lib/libvirt/images instead.
        datasets = {
          images = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "/vm";
            };
          };
          "images/default".type = "zfs_fs";
          "images/isos".type = "zfs_fs";
          "images/win10-play".type = "zfs_fs";
          "images/win10-work".type = "zfs_fs";
        };
      };

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
        options.ashift = "12";

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
