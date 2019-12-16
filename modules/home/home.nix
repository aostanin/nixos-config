{ pkgs, lib, ... }:

with lib;

let
  sysconfig = (import <nixpkgs/nixos> {}).config;
in {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    dhex
    docker-compose
    ffmpeg
    gpsbabel
    lftp
    p7zip
    python3
    pv
    rclone
    ripgrep
    rtv
    tig
    tmuxp
    translate-shell
  ] ++ optionals sysconfig.services.xserver.enable [
    # GUI
    deluge
    discord
    keepassxc
    kicad
    libreoffice
    mpv
    mullvad-vpn
    skype
    slack
    tdesktop
    thunderbird
    virtmanager
    vscodium
    (wine.override { wineBuild = "wineWow"; })
    xclip
    xorg.xmodmap
    zoom-us
  ] ++ optionals sysconfig.services.xserver.desktopManager.plasma5.enable [
    # KDE
    (ark.override { unfreeEnableUnrar = true; })
    gwenview
    kate
    kdeconnect
    krdc
    okular
    plasma-browser-integration
    spectacle
  ] ++ optionals sysconfig.programs.adb.enable [
    # Android
    android-studio
    scrcpy
  ];

  programs = {
    direnv.enable = true;

    google-chrome.enable = true;

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = false;
      withPython = false;
      withPython3 = false;
      withRuby = false;
      # TODO: extraConfig
      # TODO: plugins
    };

    tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [
        pain-control
      ];
      shortcut = "a";
      terminal = "screen-256color";
      tmuxp.enable = true;
    };
  };

  services = {
    sxhkd = {
      enable = true;
      keybindings = with pkgs; {
        "ctrl + alt + {Prior,Next}" =
          "${getBin qt5.qttools}/bin/qdbus org.kde.kglobalaccel /component/kmix invokeShortcut {increase,decrease}_volume";
      };
    };

    xcape.enable = true;
  };
}
