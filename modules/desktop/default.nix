{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.desktop;
in {
  options.localModules.desktop = {
    enable = mkEnableOption "desktop";

    enableGaming = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Add gaming packages.
      '';
    };

    hasBacklightControl = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Machine has a controllable backlight.
      '';
    };

    hasBattery = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Machine has a battery.
      '';
    };

    primaryOutput = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "eDP-1";
      description = ''
        The display output to use as primary.
      '';
    };

    output = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = {};
      example = {"HDMI-A-2" = {bg = "~/path/to/background.png fill";};};
      description = ''
        An attribute set that defines output modules. See
        {manpage}`sway-output(5)`
        for options.
      '';
    };

    workspaceOutputAssign = mkOption {
      type = with types; let
        workspaceOutputOpts = submodule {
          options = {
            workspace = mkOption {
              type = str;
              default = "";
              example = "Web";
              description = ''
                Name of the workspace to assign.
              '';
            };

            output = mkOption {
              type = either str (listOf str);
              default = "";
              example = "eDP";
              description = ''
                Name of the output.
              '';
            };
          };
        };
      in
        listOf workspaceOutputOpts;
      default = [];
      description = "Assign workspaces to outputs.";
    };

    preStartCommands = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run before starting the desktop.
      '';
    };
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
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
        openFirewall = true;
      };

      blueman.enable = true;

      gnome.gnome-keyring.enable = true;

      gvfs.enable = true;

      interception-tools = {
        enable = true;
        plugins = [pkgs.interception-tools-plugins.caps2esc];
        udevmonConfig = ''
          - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
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
        extraRules =
          ''
            # MiniPro
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="users", MODE="0660"

            # Saleae Logic
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", GROUP="users", MODE="0660"

            # LEOMO TYPE-S
            ATTR{idVendor}=="0489", ATTR{idProduct}=="c026", SYMLINK+="android_adb", MODE="0660", GROUP="adbusers", TAG+="uaccess", SYMLINK+="android", SYMLINK+="android%n"
          ''
          + optionalString cfg.enableGaming ''
            # TODO: uaccess alone doesn't work?
            KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0660", TAG+="uaccess", GROUP="input"
          '';
        packages = with pkgs;
          [
            stlink
            teensy-udev-rules
          ]
          ++ optionals cfg.enableGaming [
            pkgs.unstable.yuzu
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
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --remember \
              --user-menu \
              --cmd ${startSway}/bin/start-sway
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
        pkgs.xdg-desktop-portal-kde # Needed for Flameshot
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

      steam-hardware.enable = mkIf cfg.enableGaming true;
    };

    programs = {
      adb.enable = true;

      dconf.enable = true;
    };

    security.pam.services.lightdm.enableGnomeKeyring = true;

    virtualisation.spiceUSBRedirection.enable = true;
  };
}
