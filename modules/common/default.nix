{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: {
  imports = [
    ./packages.nix
  ];

  time.timeZone = lib.mkDefault "Asia/Tokyo";

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
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    joypixels.acceptLicense = true;
    permittedInsecurePackages = [
      "electron-12.2.3"
      "electron-19.1.9"
      "electron-24.8.6"
      "python-2.7.18.7"
      "schildichat-web-1.11.30-sc.2"
    ];
  };

  security.polkit.enable = true;

  security.sudo.wheelNeedsPassword = false;

  boot = {
    kernel.sysctl = {
      # Enable all SysRq keys
      "kernel.sysrq" = 1;
      # Don't filter bridge traffic
      "net.bridge.bridge-nf-call-arptables" = 0;
      "net.bridge.bridge-nf-call-iptables" = 0;
      "net.bridge.bridge-nf-call-ip6tables" = 0;
    };
    # Load module needed to set above sysctl
    kernelModules = ["br_netfilter"];
  };

  hardware.enableRedistributableFirmware = true;

  networking = {
    useDHCP = false;
    firewall.enable = lib.mkDefault false;
    resolvconf.dnsExtensionMechanism = false; # Disable edns0
  };

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  programs = {
    mosh.enable = true;

    zsh.enable = true;
  };

  users.users."${secrets.user.username}" = {
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
      "podman"
      "pulse-access"
      "wheel"
    ];
    shell = pkgs.zsh;
    hashedPassword = secrets.user.hashedPassword;
    openssh.authorizedKeys.keys = [secrets.user.sshKey];
  };

  users.users.root.openssh.authorizedKeys.keys = [secrets.user.sshKey];
}
