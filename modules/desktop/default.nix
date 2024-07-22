{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.desktop;
in {
  options.localModules.desktop = {
    enable = lib.mkEnableOption "desktop";

    enableGaming = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Add gaming packages.
      '';
    };

    preStartCommands = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Commands to run before starting the desktop.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      nix-ld.enable = lib.mkDefault true;
    };

    fonts.packages = with pkgs; [
      dejavu_fonts
      font-awesome
      font-awesome_4 # For compatibility
      ipafont
      joypixels
      kochi-substitute
      nerdfonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      roboto
    ];

    environment.systemPackages = with pkgs; [
      kde-gtk-config
      spice-gtk # Fix for USB redirection in virt-manager
    ];

    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      blueman.enable = true;

      gnome.gnome-keyring.enable = true;

      gvfs.enable = true;

      interception-tools = {
        enable = true;
        plugins = [pkgs.interception-tools-plugins.caps2esc];
        udevmonConfig = ''
          - JOB: "${lib.getExe' pkgs.interception-tools "intercept"} -g $DEVNODE | ${lib.getExe' pkgs.interception-tools-plugins.caps2esc "caps2esc"} -m 1 | ${lib.getExe' pkgs.interception-tools "uinput"} -d $DEVNODE"
            DEVICE:
              EVENTS:
                EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
        '';
      };

      printing = {
        enable = true;
        drivers = [pkgs.brlaser];
      };

      udev = {
        extraRules =
          ''
            # MiniPro
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="users", MODE="0660"

            # Saleae Logic
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", GROUP="users", MODE="0660"

            # LEOMO TYPE-S
            ATTR{idVendor}=="0489", ATTR{idProduct}=="c026", SYMLINK+="android_adb", MODE="0660", GROUP="adbusers", TAG+="uaccess", SYMLINK+="android", SYMLINK+="android%n"
          ''
          + lib.optionalString cfg.enableGaming ''
            # TODO: uaccess alone doesn't work?
            KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0660", TAG+="uaccess", GROUP="input"
          '';
        packages = with pkgs;
          [
            stlink
            teensy-udev-rules
          ]
          ++ lib.optionals cfg.enableGaming [
            yuzu
          ];
      };

      udisks2.enable = true;

      upower.enable = true;
    };

    services.greetd = {
      enable = true;
      vt = 7;
      settings = {
        default_session = let
          startSway = pkgs.writeScriptBin "start-sway" ''
            ${cfg.preStartCommands}
            sway --unsupported-gpu
          '';
        in {
          command = ''
            ${lib.getExe pkgs.greetd.tuigreet} \
              --time \
              --asterisks \
              --remember \
              --user-menu \
              --cmd ${lib.getExe startSway}
          '';
        };
      };
    };

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };

    # Fix for tuigreet remember not working: https://github.com/NixOS/nixpkgs/issues/248323
    systemd.tmpfiles.rules = [
      "d '/var/cache/tuigreet' - greeter greeter - -"
    ];

    xdg.portal = {
      enable = true;
      config.common.default = "*";
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    hardware = {
      bluetooth = {
        enable = true;
        settings.General.Experimental = true;
      };

      opengl = {
        enable = true;
        driSupport32Bit = true; # Needed for Steam
      };

      steam-hardware.enable = lib.mkIf cfg.enableGaming true;
    };

    programs = {
      adb.enable = true;

      dconf.enable = true;
    };

    security.pam.services.lightdm.enableGnomeKeyring = true;

    virtualisation.spiceUSBRedirection.enable = true;
  };
}
