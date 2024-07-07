{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.common;
in {
  options.localModules.common = {
    enable = lib.mkEnableOption "common";
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      msmtp.enable = lib.mkDefault true;

      tailscale.enable = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      lm_sensors
      pciutils
      smartmontools
      usbutils

      file
      git
      htop
      ncdu
      neovim
      psmisc
      tmux
      wget
      which
    ];

    localModules.nvtop.enable = true;

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
        experimental-features = ["nix-command" "flakes" "impure-derivations" "ca-derivations"];
        sandbox = "relaxed";
        trusted-users = [secrets.user.username];
      };
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
      useDHCP = lib.mkDefault false;
      firewall.enable = lib.mkDefault false;
      resolvconf.dnsExtensionMechanism = false; # Disable edns0
    };

    services = {
      openssh = {
        enable = true;
        settings = {
          X11Forwarding = true;
        };
      };

      xserver.videoDrivers = lib.mkDefault [];
    };

    programs = {
      mosh.enable = true;

      zsh.enable = true;
    };

    sops.secrets = let
      homeDirectory =
        if pkgs.stdenv.isDarwin
        then "/Users/${secrets.user.username}"
        else "/home/${secrets.user.username}";
    in {
      "user/hashed_password".neededForUsers = true;
      "user/ssh_key_${secrets.user.username}" = {
        key = "user/ssh_key";
        owner = secrets.user.username;
        path = "${homeDirectory}/.ssh/id_ed25519";
      };
    };

    users = {
      mutableUsers = false;
      users = {
        "${secrets.user.username}" = {
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
          hashedPasswordFile = config.sops.secrets."user/hashed_password".path;
          openssh.authorizedKeys.keys = [secrets.user.sshKey];
        };

        root = {
          hashedPasswordFile = config.sops.secrets."user/hashed_password".path;
          openssh.authorizedKeys.keys = [secrets.user.sshKey];
        };
      };
    };
  };
}
