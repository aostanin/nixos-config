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

  nix.autoOptimiseStore = true;
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "19.09";

  security.sudo.wheelNeedsPassword = false;

  networking = {
    firewall.enable = false;
    resolvconf.dnsExtensionMechanism = false; # Disable edns0
  };

  services.openssh = {
    enable = true;
    forwardX11 = true;
  };

  programs.zsh.enable = true;

  virtualisation.docker.enable = true;

  users.users.aostanin = {
    isNormalUser = true;
    extraGroups = [
      "adbusers"
      "cdrom"
      "docker"
      "input"
      "libvirtd"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    hashedPassword = "***REMOVED***";
    openssh.authorizedKeys.keys = [
      "***REMOVED***"
    ];
  };
}
