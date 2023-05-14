{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./audio.nix
  ];

  i18n.inputMethod = {
    enabled = "fcitx";
    fcitx.engines = with pkgs.fcitx-engines; [mozc];
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

    gvfs.enable = true;

    mullvad-vpn.enable = true;

    printing = {
      enable = true;
      drivers = [pkgs.brlaser];
    };

    udev = {
      extraRules = ''
        # MiniPro
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="users", MODE="0660"

        # Saleae Logic
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", GROUP="users", MODE="0660"

        # LEOMO TYPE-S
        ATTR{idVendor}=="0489", ATTR{idProduct}=="c026", SYMLINK+="android_adb", MODE="0660", GROUP="adbusers", TAG+="uaccess", SYMLINK+="android", SYMLINK+="android%n"
      '';
      packages = with pkgs; [
        stlink
        teensy-udev-rules
      ];
    };

    udisks2.enable = true;

    upower.enable = true;

    xbanish.enable = true;

    xserver = {
      enable = true;
      layout = "jp";
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      displayManager.lightdm.enable = true;
      windowManager.i3.enable = true;
    };
  };

  hardware = {
    bluetooth.enable = true;
    opengl.driSupport32Bit = true; # Needed for Steam
  };

  programs = {
    adb.enable = true;

    dconf.enable = true;

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        tumbler
      ];
    };
  };

  security.pam.services.lightdm.enableGnomeKeyring = true;

  virtualisation.spiceUSBRedirection.enable = true;
}
