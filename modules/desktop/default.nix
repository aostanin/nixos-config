{ config, pkgs, ... }:

{
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

  # Fix for USB redirection in virt-manager
  # ref: https://github.com/NixOS/nixpkgs/issues/39618
  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";

  environment.systemPackages = with pkgs; [
    kde-gtk-config
    spice_gtk # Fix for USB redirection in virt-manager
  ];

  location.provider = "geoclue2";

  services = {
    blueman.enable = true;
    gnome3.gnome-keyring.enable = true;
    printing.enable = true;

    redshift = {
      enable = true;
      temperature = {
        day = 5500;
        night = 3000;
      };
    };

    xbanish.enable = true;

    udev.extraRules = ''
      # MiniPro
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e11c", GROUP="users", MODE="0660"

      # Saleae Logic
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", GROUP="users", MODE="0660"
    '';

    upower.enable = true;

    xserver = {
      enable = true;
      layout = "jp";

      displayManager.lightdm.enable = true;
      desktopManager.plasma5.enable = true;
      windowManager.i3.enable = true;
    };
  };

  sound.enable = true;

  hardware = {
    bluetooth.enable = true;
    opengl.driSupport32Bit = true; # Needed for Steam
    pulseaudio = {
      enable = true;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      package = pkgs.pulseaudioFull;
    };
  };

  programs = {
    dconf.enable = true;
  };

  security.pam.services.lightdm.enableGnomeKeyring = true;

  systemd.additionalUpstreamSystemUnits = [
    "proc-sys-fs-binfmt_misc.automount"
    "proc-sys-fs-binfmt_misc.mount"
  ];
}
