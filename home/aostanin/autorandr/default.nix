{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.autorandr = {
    enable = true;
    hooks.postswitch = {
      "change-background" = "${pkgs.nitrogen}/bin/nitrogen --restore";
    };
    profiles = {
      "ThinkPad Docked Home" = {
        fingerprint = {
          DP2-1 = "00ffffffffffff001e6d2e77bbcd0200081d010380502278eaca95a6554ea1260f50542108007140818081c0a9c0b300d1c081000101e77c70a0d0a0295030203a00204f3100001a9d6770a0d0a0225030203a00204f3100001a000000fd00383d1e5a20000a202020202020000000fc004c472048445220575148440a2001a7020340f1230907074e01030405101213141f5d5e5f6061830100006d030c002000b83c20006001020367d85dc401788003e30f0030e305c000e60605015952569f3d70a0d0a0155030203a00204f3100001a7e4800e0a0381f4040403a00204f31000018000000ff003930384e544d5835443733390a000000000000000000de";
          DP2-2 = "00ffffffffffff0010ac80404c35303203170104a53c22783a4bb5a7564ba3250a5054a54b008100b300d100714fa940818001010101565e00a0a0a029503020350055502100001a000000ff00474b304b443331453230354c0a000000fc0044454c4c205532373133484d0a000000fd0031561d711e010a202020202020012002031df15090050403020716010611121513141f2023097f0783010000023a801871382d40582c250055502100001e011d8018711c1620582c250055502100009e011d007251d01e206e28550055502100001e8c0ad08a20e02d10103e960055502100001800000000000000000000000000000000000000000000000000005d";
          eDP-1 = "*";
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
            mode = "2560x1440";
          };
          eDP-1 = {
            enable = true;
            position = "3440x1440";
            mode = "1920x1080";
          };
        };
      };
      "ThinkPad Docked Parents" = {
        fingerprint = {
          VGA-1 = "00ffffffffffff005a631b4c01010101030f01030e221b782ac5c6a3574a9c23124f54bfef808180714f615945593159010101010101302a009851002a4030701300520e1100001e000000ff00504a4b3035303330303531350a000000fd0032551e520e000a202020202020000000fc005650313731622d320a2020202000cf";
          eDP-1 = "*";
        };
        config = {
          VGA-1 = {
            enable = true;
            position = "1920x0";
            mode = "1280x1024";
            rotate = "left";
          };
          eDP-1 = {
            enable = true;
            primary = true;
            position = "0x200";
            mode = "1920x1080";
          };
        };
      };
      "ThinkPad Mobile" = {
        fingerprint = {
          eDP-1 = "*";
        };
        config = {
          eDP-1 = {
            enable = true;
            primary = true;
            mode = "1920x1080";
          };
        };
      };
    };
  };
}
