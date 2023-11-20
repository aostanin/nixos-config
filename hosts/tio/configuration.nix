{
  config,
  pkgs,
  hardwareModulesPath,
  secrets,
  ...
}: {
  imports = [
    "${hardwareModulesPath}/raspberry-pi/4"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/common
    ../../modules/zerotier
  ];

  networking = {
    hostName = "tio";
    hostId = "9d6a993f";

    vlans.vlan10 = {
      id = 10;
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

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = secrets.network.home.nameserversAdguard;

    firewall = {
      enable = true;
      trustedInterfaces = [
        "eth0"
      ];
      allowedTCPPorts = [
        22 # SSH
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    ncmpcpp
    cifs-utils
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
