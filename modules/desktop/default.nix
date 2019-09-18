{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
  };

  fonts.fonts = with pkgs; [
    dejavu_fonts
    ipafont
    kochi-substitute
  ];

  services = {
    dbus.packages = [ pkgs.gnome3.dconf ];

    printing.enable = true;

    redshift = {
      enable = true;
      provider = "geoclue2";
    };

    udev.extraRules = ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="plugdev", MODE="0666" # MiniPro
    '';

    xbanish.enable = true;

    xserver = {
      enable = true;
      layout = "jp";

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

  systemd.user.services.sxhkd = {
    description = "Simple X hotkey daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sxhkd}/bin/sxhkd";
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

  programs = {
    dconf.enable = true;
  };
}
