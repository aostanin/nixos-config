{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  imports = [
    ./packages.nix
  ];

  time.timeZone = "Asia/Tokyo";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "jp106";
  };

  i18n = {
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
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;
    joypixels.acceptLicense = true;
    permittedInsecurePackages = [
      "electron-12.2.3"
      "electron-13.6.9" # TODO: Needed for SchildiChat
      "electron-14.2.9" # TODO: Needed for something?
    ];
  };

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
    hashedPassword = secrets.user.hashedPassword;
    openssh.authorizedKeys.keys = [ secrets.user.sshKey ];
  };

  users.users.root.openssh.authorizedKeys.keys = [ secrets.user.sshKey ];
}
