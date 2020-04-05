{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
  ];

  time.timeZone = "Asia/Tokyo";

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "jp106";
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
      LC_MONETRY = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
    };
  };

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  security.sudo.wheelNeedsPassword = false;

  boot = {
    # Don't filter bridge traffic
    kernel.sysctl = {
      "net.bridge.bridge-nf-call-arptables" = 0;
      "net.bridge.bridge-nf-call-iptables" = 0;
      "net.bridge.bridge-nf-call-ip6tables" = 0;
    };
    # Load module needed to set above sysctl
    kernelModules = [ "br_netfilter" ];
  };

  networking = {
    useDHCP = false;
    firewall.enable = false;
    resolvconf.dnsExtensionMechanism = false; # Disable edns0
  };

  services.openssh = {
    enable = true;
    forwardX11 = true;
  };

  programs.zsh.enable = true;

  users.users.aostanin = {
    isNormalUser = true;
    extraGroups = [
      "adbusers"
      "cdrom"
      "dialout"
      "disk"
      "docker"
      "input"
      "libvirtd"
      "networkmanager"
      "plugdev"
      "wheel"
    ];
    shell = pkgs.zsh;
    hashedPassword = "***REMOVED***";
    openssh.authorizedKeys.keys = [
      "***REMOVED***"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "***REMOVED***"
  ];
}
