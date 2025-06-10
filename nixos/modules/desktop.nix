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
    fonts.packages = with pkgs; [
      dejavu_fonts
      font-awesome
      font-awesome_4 # For compatibility
      ipafont
      ipaexfont
      joypixels
      kochi-substitute
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      roboto
    ];

    environment.systemPackages = with pkgs; [
      kdePackages.kde-gtk-config
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

            # Blockstream Jade
            ATTRS{idProduct}=="55d4", ATTRS{idVendor}=="1a86", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on", GROUP="plugdev", MODE="0660", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="jade%n"

            # Trezor
            SUBSYSTEM=="usb", ATTR{idVendor}=="534c", ATTR{idProduct}=="0001", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="trezor%n"
            KERNEL=="hidraw*", ATTRS{idVendor}=="534c", ATTRS{idProduct}=="0001", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"

            # Trezor v2
            SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="53c0", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="trezor%n"
            SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="53c1", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="trezor%n"
            KERNEL=="hidraw*", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="53c1", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
          ''
          + lib.optionalString cfg.enableGaming ''
            # TODO: uaccess alone doesn't work?
            KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0660", TAG+="uaccess", GROUP="input"
          '';
        packages = with pkgs;
          [
            stlink
            platformio-core.udev
            teensy-udev-rules
          ]
          ++ lib.optionals cfg.enableGaming [
            nur.repos.aprilthepink.suyu-mainline
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
      wireplumber.extraConfig = {
        # Workaround for wireplumber keeping camera device open
        # ref: https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2669#note_2362342
        # TODO: Remove once fixed
        "10-disable-camera" = {
          "wireplumber.profiles" = {
            main = {
              "monitor.libcamera" = "disabled";
            };
          };
        };
        "wh-1000xm3-ldac-hq" = {
          "monitor.bluez.rules" = [
            {
              matches = [
                {
                  "device.name" = "~bluez_card.*";
                  "device.product.id" = "0x0cd3";
                  "device.vendor.id" = "usb:054c";
                }
              ];
              actions = {
                update-props = {
                  "bluez5.a2dp.ldac.quality" = "hq";
                };
              };
            }
          ];
        };
      };
    };

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

      graphics = {
        enable = true;
        enable32Bit = true; # Needed for Steam
      };

      printers.ensurePrinters = [
        {
          name = "Brother_HL-2270DW_series";
          description = "Brother HL-2270DW series";
          location = "Local Printer";
          model = "drv:///brlaser.drv/br2270dw.ppd";
          deviceUri = "dnssd://Brother%20HL-2270DW%20series._pdl-datastream._tcp.local/";
          ppdOptions = {
            Duplex = "DuplexNoTumble";
            PageSize = "A4";
          };
        }
      ];

      steam-hardware.enable = lib.mkIf cfg.enableGaming true;
    };

    programs = {
      adb.enable = true;

      dconf.enable = true;
    };

    security.pam.services.swaylock = {};

    virtualisation.spiceUSBRedirection.enable = true;

    users.groups.plugdev = {};
  };
}
