{ pkgs, lib, ... }:

with lib;

let
  sysconfig = (import <nixpkgs/nixos> {}).config;
  unstable = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz) {};
in {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    bat
    dhex
    docker-compose
    fd
    ffmpeg
    gpsbabel
    ipmitool
    lazygit
    lftp
    p7zip
    python3
    pv
    rclone
    ripgrep
    rtv
    tig
    tmuxp
    tokei
    translate-shell
    wol
  ] ++ optionals sysconfig.services.xserver.enable [
    # GUI
    deluge
    discord
    keepassxc
    kicad
    libreoffice
    mullvad-vpn
    skype
    slack
    tdesktop
    thunderbird
    virtmanager
    (wine.override { wineBuild = "wineWow"; })
    xclip
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
  } // optionalAttrs sysconfig.services.xserver.enable {
    mpv.enable = true;

    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        bbenoist.Nix
        vscodevim.vim
        # TODO: Add others like https://github.com/NixOS/nixpkgs/blob/master/pkgs/misc/vscode-extensions/default.nix
        # Tom Philbin - Gruvbox Themes
      ];
      userSettings = {
        "editor.wordWrap" = "on";
        "update.channel" = "none";
        "workbench.colorTheme" = "Gruvbox Dark (Medium)";
        "vim.useCtrlKeys" = false;
      };
    };
  };

  services = {
  } // optionalAttrs sysconfig.services.xserver.enable {
    sxhkd = {
      enable = true;
      keybindings = with pkgs; {
        "ctrl + alt + {Prior,Next}" = # volume control
          "${getBin qt5.qttools}/bin/qdbus org.kde.kglobalaccel /component/kmix invokeShortcut {increase,decrease}_volume";
      } // optionalAttrs (sysconfig.networking.hostName == "valmar") {
        "ctrl + alt + {1,2,3,4}" = # input switching
          "/run/wrappers/bin/sudo ${ddcutil}/bin/ddcutil setvcp 60 0x0{1,3,4,f}";
        "ctrl + alt + 0" = # turn off display
          "/run/wrappers/bin/sudo ${ddcutil}/bin/ddcutil setvcp d6 0x05";
      };
    };

    xcape.enable = true;
  };
}
