{ pkgs, config, lib, ... }:

with lib;

{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      # TODO: Not supported on 19.09
      # terminal = "konsole";
      focus.followMouse = false;
      keybindings =
        let modifier = config.xsession.windowManager.i3.config.modifier;
        in mkOptionDefault {
          "${modifier}+Return" = "exec konsole";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show combi";
        };
      bars = [ {
        trayOutput = "primary";
      } ];
    };
    extraConfig = ''
      exec --no-startup-id xset dpms 600
      exec --no-startup-id ${pkgs.autorandr}/bin/autorandr --change
      exec --no-startup-id ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable
      exec --no-startup-id ${pkgs.pasystray}/bin/pasystray
      exec --no-startup-id ${pkgs.barrier}/bin/barrier

      for_window [class="mpv"] floating enable border none
      for_window [class=".*scrcpy.*"] floating enable border none
    '';
  };

  home.packages = with pkgs; [
    arandr
    pavucontrol
  ];

  programs = {
    autorandr = {
      enable = true;
      hooks.postswitch = {
        "change-background" = "${pkgs.nitrogen}/bin/nitrogen --restore";
      };
      profiles = {
        "Desktop" = {
          fingerprint = {
            DP1 = "00ffffffffffff0010ac80404c35303203170104a53c22783a4bb5a7564ba3250a5054a54b008100b300d100714fa940818001010101565e00a0a0a029503020350055502100001a000000ff00474b304b443331453230354c0a000000fc0044454c4c205532373133484d0a000000fd0031561d711e010a202020202020012002031df15090050403020716010611121513141f2023097f0783010000023a801871382d40582c250055502100001e011d8018711c1620582c250055502100009e011d007251d01e206e28550055502100001e8c0ad08a20e02d10103e960055502100001800000000000000000000000000000000000000000000000000005d";
            HDMI2 = "00ffffffffffff001e6d2e77bbcd0200081d010380502278eaca95a6554ea1260f50542108007140818081c0a9c0b300d1c081000101e77c70a0d0a0295030203a00204f3100001a9d6770a0d0a0225030203a00204f3100001a000000fd00383d1e5a20000a202020202020000000fc004c472048445220575148440a2001a7020340f1230907074e01030405101213141f5d5e5f6061830100006d030c001000b83c20006001020367d85dc401788003e30f0030e305c000e60605015952569f3d70a0d0a0155030203a00204f3100001a7e4800e0a0381f4040403a00204f31000018000000ff003930384e544d5835443733390a000000000000000000ee";
          };
          config = {
            DP1 = {
              enable = true;
              position = "440x0";
              mode = "2560x1440";
            };
            HDMI2 = {
              enable = true;
              primary = true;
              position = "0x1440";
              mode = "3440x1440";
            };
          };
        };
        "ThinkPad Docked Home" = {
          fingerprint = {
            DP2-1 = "00ffffffffffff001e6d2e77bbcd0200081d010380502278eaca95a6554ea1260f50542108007140818081c0a9c0b300d1c081000101e77c70a0d0a0295030203a00204f3100001a9d6770a0d0a0225030203a00204f3100001a000000fd00383d1e5a20000a202020202020000000fc004c472048445220575148440a2001a7020340f1230907074e01030405101213141f5d5e5f6061830100006d030c002000b83c20006001020367d85dc401788003e30f0030e305c000e60605015952569f3d70a0d0a0155030203a00204f3100001a7e4800e0a0381f4040403a00204f31000018000000ff003930384e544d5835443733390a000000000000000000de";
            DP2-2 = "00ffffffffffff0010ac7e404c35303203170103803c2278ea4bb5a7564ba3250a5054a54b008100b300d100714fa9408180d1c00101343c80a070b0234030203600ffff0000001e000000ff00474b304b443331453230354c0a000000fc0044454c4c205532373133484d0a000000fd0031561d711c000a20202020202000ca";
            eDP1 = "*";
          };
          config = {
            DP2-1 = {
              enable = true;
              primary = true;
              position = "0x1440";
              mode = "3440x1440";
            };
            DP2-2 = {
              enable = true;
              position = "440x0";
              mode = "2560x1440_41";
            };
            eDP1 = {
              enable = true;
              position = "3440x1440";
              mode = "1920x1080";
            };
          };
          hooks.preswitch = "xrandr --newmode 2560x1440_41 162.00 2560 2608 2640 2720 1440 1443 1448 1468 +hsync +vsync; xrandr --addmode DP2-2 2560x1440_41";
        };
        "ThinkPad Mobile" = {
          fingerprint = {
            eDP1 = "*";
          };
          config = {
            eDP1 = {
              enable = true;
              mode = "1920x1080";
            };
          };
        };
      };
    };

    rofi = {
      enable = true;
      theme = "glue_pro_blue";
      extraConfig = ''
        rofi.modi: window,drun,run,ssh,combi
        rofi.combi-modi: window,drun,ssh
        rofi.show-icons: true
      '';
    };
  };

  services = {
    compton = {
      enable = true;
    };

    dunst = {
      enable = true;
    };

    kdeconnect = {
      enable = true;
      indicator = true;
    };

    # TODO: Not supported on 19.09
    # grobi = {
    #   enable = true;
    #   rules = [
    #     {
    #       name = "Desktop";
    #       outputs_connected = [ "HDMI2" ];
    #       outputs_absent = [ "eDP-1" ];
    #       configure_single = "HDMI2";
    #       # TODO: Disable lock?
    #     }
    #     {
    #       name = "Laptop Docked Home";
    #       outputs_connected = [ "eDP-1" "DP-2-1" ];
    #       configure_row = [ "DP-2-1" "eDP-1" ];
    #       primary = [ "DP-2-1" ];
    #       # TODO: Disable lock?
    #     }
    #     {
    #       name = "Laptop Mobile";
    #       ouputs_disconnected = [ "DP-2-1" ];
    #       configure_single = "eDP-1";
    #     }
    #   ];
    # };

    redshift = {
      enable = true;
      provider = "geoclue2";
      tray = true;
      temperature = {
        day = 6500;
        night = 3000;
      };
    };

    screen-locker = {
      enable = true;
      inactiveInterval = 10;
    };

    udiskie = {
      enable = true;
      automount = false;
      tray = "always";
    };
  };
}
