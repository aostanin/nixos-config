{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./audio.nix
  ];

  fonts.fonts = with pkgs; [
    dejavu_fonts
    font-awesome
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

    interception-tools = {
      enable = true;
      plugins = [pkgs.interception-tools-plugins.caps2esc];
      udevmonConfig = ''
        - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
      '';
    };

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
  };

  services.greetd = {
    enable = true;
    vt = 7;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --remember \
            --user-menu \
            --cmd sway
        '';
      };
    };
  };

  # Fix for tuigreet remember not working: https://github.com/NixOS/nixpkgs/issues/248323
  systemd.tmpfiles.rules = [
    "d '/var/cache/tuigreet' - greeter greeter - -"
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-kde # Needed for Flameshot
    ];
  };

  hardware = {
    bluetooth.enable = true;
    opengl = {
      enable = true;
      driSupport32Bit = true; # Needed for Steam
    };
  };

  programs = {
    adb.enable = true;

    dconf.enable = true;
  };

  security.pam.services.lightdm.enableGnomeKeyring = true;

  virtualisation.spiceUSBRedirection.enable = true;
}
