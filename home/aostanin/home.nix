sysconfig:
{ pkgs, config, lib, ... }:

with lib;

{
  imports = [
    ./git
    ./neovim
    ./ssh
    ./tmux
    ./zsh
  ] ++ optionals sysconfig.services.xserver.enable [
    ./alacritty
    ./vscode
  ] ++ optionals sysconfig.services.xserver.windowManager.i3.enable  [
    ./autorandr
    ./dunst
    ./i3
  ] ++ optionals sysconfig.services.xserver.desktopManager.plasma5.enable [
    ./plasma
  ] ++ optionals sysconfig.programs.adb.enable [
    ./android
  ];

  nixpkgs.config = import ./nixpkgs/config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs/config.nix;

  nixpkgs.overlays = import ./nixpkgs/overlays.nix;
  xdg.configFile."nixpkgs/overlays.nix".source = ./nixpkgs/overlays.nix;

  home = {
    packages = with pkgs; [
      bat
      catt
      dhex
      fd
      ffmpeg
      gpsbabel
      ipmitool
      lazygit
      lftp
      p7zip
      personal-scripts
      python3
      pv
      ranger
      rclone
      ripgrep
      rtv
      tig
      tmuxp
      tokei
      translate-shell
      wol

      # Sailing the seven seas
      beets
      cksfv
    ] ++ optionals sysconfig.services.xserver.enable [
      # GUI
      barrier
      bitwarden
      discord
      unstable.etcher
      filezilla
      gimp
      keepassxc
      kicad
      krita
      libreoffice
      mullvad-vpn
      skype
      slack
      syncthing-gtk
      tdesktop
      thunderbird
      virtmanager
      (wine.override { wineBuild = "wineWow"; })
      xclip
      zoom-us
    ];

    sessionVariables = {
      EDITOR = "vi";
      VISUAL = config.home.sessionVariables.EDITOR;
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
    };
  };

  programs = {
    direnv.enable = true;
    lsd = {
      enable = true;
      enableAliases = true;
    };
    starship.enable = true;
  } // optionalAttrs sysconfig.services.xserver.enable {
    firefox.enable = true;
    google-chrome.enable = true;
    mpv.enable = true;
  };

  services = {
    lorri.enable = true;
  } // optionalAttrs sysconfig.services.xserver.enable {
    sxhkd = {
      enable = true;
      keybindings = with pkgs; {
        "ctrl + alt + {Prior,Next}" = # volume control
          "${pamixer}/bin/pamixer -{i,d} 5";
      } // optionalAttrs (sysconfig.networking.hostName == "valmar") {
        "ctrl + alt + {1,2,3,4}" = # input switching
          "/run/wrappers/bin/sudo ${ddcutil}/bin/ddcutil --bus 3 setvcp 60 0x0{1,3,4,f}";
        "ctrl + alt + 0" = concatStringsSep " && " [ # turn off display
          "/run/wrappers/bin/sudo ${ddcutil}/bin/ddcutil --bus 0 setvcp d6 0x05"
          "/run/wrappers/bin/sudo ${ddcutil}/bin/ddcutil --bus 3 setvcp d6 0x05"
        ];
      };
    };

    xcape.enable = true;
  };

  xdg.configFile = {
    "catt/catt.cfg".text = ''
      [options]
      device = up

      [aliases]
      up = Upstairs TV
      down = Downstairs Home Hub
    '';

    "libvirt/libvirt.conf".text = ''
      uri_default='qemu:///system'
    '';
  };
}
