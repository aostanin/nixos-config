{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.localModules.desktop-linux;
in {
  options.localModules.desktop-linux = {
    enable = lib.mkEnableOption "desktop-linux";
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      "3dprinting".enable = lib.mkDefault true;
      android.enable = lib.mkDefault true;
      chromium.enable = lib.mkDefault true;
      electronics.enable = lib.mkDefault true;
      firefox.enable = lib.mkDefault true;
      foot.enable = lib.mkDefault true;
      gnupg.enable = lib.mkDefault true;
      gtk.enable = lib.mkDefault true;
      obs-studio.enable = lib.mkDefault true;
      polkit.enable = lib.mkDefault true;
      qt.enable = lib.mkDefault true;
      sway.enable = lib.mkDefault true;
      syncthing.enable = lib.mkDefault true;
      video.enable = lib.mkDefault true;
      vscode.enable = lib.mkDefault true;
    };

    home = {
      packages = with pkgs;
        [
          # GUI
          audacity
          bitwarden-desktop
          feishin
          filezilla
          gimp
          gparted
          jellyfin-media-player
          kooha
          krita
          libreoffice
          moonlight-qt
          sparrow
          steam
          (xfce.thunar.override {
            thunarPlugins = with xfce; [
              thunar-archive-plugin
              thunar-volman
              tumbler
            ];
          })
          thunderbird
          virt-manager
          wineWowPackages.stable
          wl-clipboard
          zathura

          # Chat
          discord
          element-desktop
          slack

          # AI
          inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
        ]
        ++ (with pkgs.kdePackages; [
          # Plasma
          ark
          gwenview
          kate
          krdc
          okular
          spectacle
        ]);
    };

    programs = {
      mpv = {
        enable = true;
        package = pkgs.mpv-unwrapped.override {ffmpeg = pkgs.ffmpeg.override {withV4l2 = true;};};
        config.hwdec = "auto";
      };
    };

    services = {
      blueman-applet.enable = true;

      mpris-proxy.enable = true;
    };
  };
}
