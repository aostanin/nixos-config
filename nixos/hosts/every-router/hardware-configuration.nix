{lib, ...}: {
  sbc = {
    version = "0.3";
    bootstrap.rootFilesystem = "ext4";
    wireless.wifi.acceptRegulatoryResponsibility = true;
  };

  fileSystems = let
    btrfsDevice = "/dev/disk/by-uuid/2b18a0c0-3e90-4194-bcee-c94a3bbb7800";
  in {
    "/boot" = {
      device = "/dev/disk/by-uuid/0b5e3376-c7e9-4284-9514-9c3b51244f19";
      fsType = "ext4";
    };
    "/" = lib.mkForce {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["compress=zstd" "subvol=/@"];
    };
    "/nix" = {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["compress=zstd" "subvol=/@nix" "noatime"];
    };
    "/home" = {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["compress=zstd" "subvol=/@home"];
    };
  };
}
