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
}
