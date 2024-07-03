{secrets, ...}: {
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
    options = ["rbind" "x-systemd.requires=zfs-mount.service"];
  };

  services.nfs.server = {
    enable = true;
    hostName = secrets.network.storage.hosts.elena.address;
    exports = ''
      /srv/nfs             ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,fsid=0)
      /srv/nfs/home        ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
      /srv/nfs/media       ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,crossmnt)
      /srv/nfs/personal    ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,crossmnt)
    '';
  };
}
