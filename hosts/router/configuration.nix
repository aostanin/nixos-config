{ config, pkgs, hardwareModulesPath, ... }:
let
  secrets = import ../../secrets;
  iface = "enp1s0";
  iface_lan = "enp7s0";
in
{
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/zerotier
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      # For virsh console
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };

  systemd.package = pkgs.systemd.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # network: tunnel: automatic local address selection
      # ref: https://github.com/systemd/systemd/pull/21648
      ./patches/systemd-21648.patch
    ];
  });

  networking = {
    hostName = "router";

    nameservers = [
      "8.8.8.8"
    ];

    useNetworkd = true;
    useDHCP = false;

    bridges.lan.interfaces = [ iface_lan ];
    interfaces.lan = {
      ipv4.addresses = [{
        address = "192.168.0.1";
        prefixLength = 24;
      }];
    };

    vlans = {
      wan = { id = 10; interface = iface; };
      #guest = { id = 20; interface = iface; };
      #iot = { id = 40; interface = iface; };
    };
  };

  systemd.network = {
    netdevs.transix = {
      netdevConfig = {
        Name = "transix";
        Kind = "ip6tnl";
      };
      tunnelConfig = {
        Mode = "ipip6";
        Remote = "2404:8e00::feed:100";
        Local = "slaac";
      };
    };
    networks.transix = {
      matchConfig.Name = "transix";
      networkConfig = {
        IPForward = "ipv4";
        Address = "192.0.0.2";
      };
      routes = [
        { routeConfig = { Destination = "0.0.0.0/0"; }; }
      ];
    };

    networks.wan = {
      matchConfig.Name = "wan";
      networkConfig = {
        Tunnel = "transix";
      };
    };
  };

  services.pppd = {
    #enable = true;
    peers.iij = {
      autostart = true;
      enable = true;
      config = ''
        plugin rp-pppoe.so wan

        name "${secrets.pppoe.username}"
        password "${secrets.pppoe.password}"

        persist
        maxfail 0
        holdoff 5

        noipdefault
        #defaultroute
      '';
    };
  };

  services.dnsmasq = {
    enable = true;
    servers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
    extraConfig = ''
      interface=lan
      dhcp-range=192.168.0.100,192.168.0.254,24h
    '';
  };
  # TODO: Why is this enabled in the first place?
  systemd.services.systemd-resolved.enable = false;
}
