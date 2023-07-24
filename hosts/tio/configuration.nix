{
  config,
  pkgs,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
in {
  imports = [
    "${hardwareModulesPath}/raspberry-pi/4"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/zerotier
    ../../modules
  ];

  boot = {
    supportedFilesystems = ["zfs"];
  };

  networking = {
    hostName = "tio";
    hostId = "9d6a993f";
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.tio.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = secrets.network.home.nameserversAdguard;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    ncmpcpp
    cifs-utils
  ];

  virtualisation.libvirtd = {
    enable = true;
    # viriscsitest fails
    package = pkgs.libvirt.overrideAttrs (old: {doCheck = false;});
  };

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
    # Docker defaults to Google's DNS
    extraOptions = ''
      --dns ${secrets.network.home.nameserver} \
      --dns-search lan
    '';
  };

  services.mpd = {
    enable = true;
    network.listenAddress = "any";
    musicDirectory = "/mnt/music";
  };

  fileSystems."/mnt/music" = {
    device = "//${secrets.network.home.hosts.elena.address}/media/music";
    fsType = "cifs";
    options = ["ro" "x-systemd.automount" "noauto" "x-systemd.idle-timeout=60" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"];
  };
}
