{modulesPath, ...}: {
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-label/ssd";
    fsType = "ext4";
  };
  fileSystems."/storage/appdata/docker/ssd" = {
    device = "/mnt/ssd/appdata/docker";
    options = ["bind"];
  };
  fileSystems."/var/lib/docker" = {
    device = "/mnt/ssd/var/lib/docker";
    options = ["bind"];
  };
}
