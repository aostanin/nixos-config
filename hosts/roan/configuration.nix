# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/x250"
    "${nixos-hardware}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "roan";
    networkmanager.enable = true;
    firewall.enable = false;
  };

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

    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
    };
  };

  fonts.fonts = with pkgs; [
    dejavu_fonts
    ipafont
    kochi-substitute
  ];

  time.timeZone = "Asia/Tokyo";

  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    usbutils

    file
    git
    gnumake
    htop
    ncdu
    neovim
    stow
    tmux
    vim
    wget
    which
  ];

  services = {
    dbus.packages = [ pkgs.gnome3.dconf ];
    flatpak.enable = true;

    openssh = {
      enable = true;
      permitRootLogin = "no";
    };

    printing.enable = true;

    redshift = {
      enable = true;
      provider = "geoclue2";
    };

    tlp = {
      enable = true;
      extraConfig = ''
        START_CHARGE_THRESH_BAT0=75 
        STOP_CHARGE_THRESH_BAT0=80
        START_CHARGE_THRESH_BAT1=75
        STOP_CHARGE_THRESH_BAT1=80
      '';
    };

    udev.extraRules = ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="plugdev", MODE="0666" # MiniPro
    '';

    xbanish.enable = true;

    xserver = {
      enable = true;
      layout = "jp";
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      libinput = {
        enable = true;
        clickMethod = "clickfinger";
        naturalScrolling = true;
      };

      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };

  systemd.user.services.xcape = {
    description = "xcape to use CTRL as ESC when pressed alone";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.xcape}/bin/xcape";
      RestartSec = 3;
      Restart = "always";
    };
  };

  sound.enable = true;

  hardware = {
    bluetooth.enable = true;
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  programs = {
    dconf.enable = true;
    zsh.enable = true;
  };

  users.users.aostanin = {
    isNormalUser = true;
    extraGroups = [
      "docker"
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

  nix.autoOptimiseStore = true;
  nixpkgs.config.allowUnfree = true;

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  system.stateVersion = "19.03";
}
