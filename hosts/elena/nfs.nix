{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  fileSystems."/srv/nfs/libvirt/images" = {
    device = "/var/lib/libvirt/images/tank";
    options = ["rbind" "x-systemd.requires=zfs-mount.service"];
  };

  fileSystems."/srv/nfs/home" = {
    device = "/home";
    options = ["rbind" "x-systemd.requires=zfs-mount.service"];
  };

  fileSystems."/srv/nfs/media" = {
    device = "/storage/media";
    options = ["rbind" "x-systemd.requires=zfs-mount.service"];
  };

  fileSystems."/srv/nfs/personal" = {
    device = "/storage/personal";
    options = ["bind" "x-systemd.requires=zfs-mount.service"];
  };

  fileSystems."/srv/nfs/appdata/temp/tdarr" = {
    device = "/storage/appdata/temp/tdarr";
    options = ["bind" "x-systemd.requires=zfs-mount.service"];
  };

  services.nfs.server = {
    enable = true;
    hostName = secrets.network.storage.hosts.elena.address;
    exports = ''
      /srv/nfs             ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,fsid=0)
      /srv/nfs/home        ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
      /srv/nfs/media       ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,crossmnt)
      /srv/nfs/personal    ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
      /srv/nfs/libvirt/images ${secrets.network.storage.hosts.elena.address}/24(insecure,no_root_squash,rw,crossmnt)
      /srv/nfs/appdata/temp/tdarr ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
    '';
  };
}
