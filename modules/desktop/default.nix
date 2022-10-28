{ config, pkgs, ... }:

{
  imports = [
    ./audio.nix
  ];

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];
    kernelModules = [
      "v4l2loopback"
    ];
    extraModprobeConfig = ''
      options v4l2loopback video_nr=10 card_label="OBS Studio" exclusive_caps=1
    '';
  };

  i18n.inputMethod = {
    enabled = "fcitx";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
  };

  fonts.fonts = with pkgs; [
    dejavu_fonts
    ipafont
    joypixels
    kochi-substitute
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  environment.systemPackages = with pkgs; [
    kde-gtk-config
    spice-gtk # Fix for USB redirection in virt-manager
  ];

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
    };

    blueman.enable = true;

    gnome.gnome-keyring.enable = true;

    mullvad-vpn.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };

    udev.extraRules = ''
      # MiniPro
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="users", MODE="0660"

      # Saleae Logic
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", GROUP="users", MODE="0660"
    '';

    upower.enable = true;

    xbanish.enable = true;

    xserver = {
      enable = true;
      layout = "jp";
      displayManager.lightdm.enable = true;
      windowManager.i3.enable = true;

      desktopManager.xfce = {
        enable = true;
        noDesktop = true;
        thunarPlugins = with pkgs.xfce; [
          thunar-archive-plugin
          thunar-volman
          tumbler
        ];
      };
    };
  };

  hardware = {
    bluetooth.enable = true;
    opengl.driSupport32Bit = true; # Needed for Steam
  };

  programs = {
    dconf.enable = true;
  };

  security.pam.services.lightdm.enableGnomeKeyring = true;

  virtualisation.spiceUSBRedirection.enable = true;
}
