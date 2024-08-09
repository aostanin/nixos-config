{
  config,
  pkgs,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/raspberry-pi/4"
    ./hardware-configuration.nix
  ];

  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "tio";
    hostId = "9d6a993f";

    vlans.vlan40 = {
      id = 40;
      interface = "br0";
    };

    bridges.br0.interfaces = ["eth0"];
    interfaces.br0 = {
      macAddress = secrets.network.home.hosts.tio.macAddress;
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.tio.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces.vlan40 = {
      ipv4.addresses = [
        {
          address = secrets.network.iot.hosts.tio.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = secrets.network.home.nameserversAdguard;
  };

  localModules = {
    common.enable = true;

    zfs.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  virtualisation = {
    docker = {
      enable = true;
      liveRestore = false;
      # Docker defaults to Google's DNS
      extraOptions = ''
        --dns ${secrets.network.home.nameserver} \
        --dns-search lan
      '';
    };

    libvirtd.enable = true;
  };
}
