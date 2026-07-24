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
              size = "477G";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                resumeDevice = true;
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
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          # disko-zfs reconciles this every boot, so it must hold the runtime
          # value. For a reinstall, temporarily set "file:///tmp/disk.key" and
          # pass nixos-anywhere --disk-encryption-keys /tmp/disk.key <keyfile>.
          keylocation = "prompt";
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
