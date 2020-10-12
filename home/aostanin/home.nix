sysconfig:
{ pkgs, config, lib, ... }:

with lib;

{
  imports = [
    ./fish
    ./git
    ./mpd
    ./neovim
    ./newsboat
    ./ssh
    ./tmux
    ./zsh
  ] ++ optionals sysconfig.services.xserver.enable [
    ./alacritty
    ./chrome
    ./electronics
    ./gnupg
    ./obs-studio
    ./vscode
  ] ++ optionals sysconfig.services.xserver.windowManager.i3.enable [
    ./autorandr
    ./dunst
    (import ./i3 (sysconfig))
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
      (beets.override { enableSonosUpdate = false; })
      catt
      cksfv
      ctop
      dhex
      exa
      fd
      ffmpeg
      github-cli
      gpsbabel
      ipmitool
      lazygit
      lftp
      nsz
      (p7zip.override { enableUnfree = true; })
      personal-scripts
      pv
      python3
      ranger
      rclone
      ripgrep
      tig
      tmuxp
      tokei
      translate-shell
      tuir
      wol
      youtube-dl
      unstable.ytop # TODO: switch to stable once it no longer crashes on elena
    ] ++ optionals sysconfig.services.xserver.enable [
      # GUI
      barrier
      bitwarden
      unstable.etcher
      filezilla
      gimp
      gparted
      unstable.jellyfin-mpv-shim
      keepassxc
      krita
      libreoffice
      peek
      steam
      syncthing-gtk
      thunderbird
      virtmanager
      wineWowPackages.stable
      xclip

      # Chat
      discord
      unstable.element-desktop
      slack
      tdesktop
      unstable.zoom-us
    ] ++ optionals (elem "nvidia" sysconfig.services.xserver.videoDrivers) [
      # Nvidia drivers installed
      nvtop
    ];

    sessionVariables = {
      EDITOR = "vi";
      VISUAL = config.home.sessionVariables.EDITOR;
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
    };
  };

  programs =
    {
      direnv.enable = true;
      starship.enable = true;
    }
    // optionalAttrs sysconfig.services.xserver.enable {
      firefox.enable = true;
      mpv.enable = true;
    };

  services =
    {
      lorri.enable = true;
    }
    // optionalAttrs sysconfig.services.xserver.enable {
      blueman-applet.enable = true;

      sxhkd = {
        enable = true;
        keybindings = with pkgs;
          {
            "ctrl + alt + {Prior,Next}" =
              "${pamixer}/bin/pamixer -{i,d} 5";
            "{XF86AudioRaiseVolume,XF86AudioLowerVolume}" =
              "${pamixer}/bin/pamixer -{i,d} 5";
            "XF86AudioMute" =
              "${pamixer}/bin/pamixer -t";
            "{XF86MonBrightnessUp,XF86MonBrightnessDown}" =
              "${xorg.xbacklight}/bin/xbacklight -{inc,dec} 10";
          }
          // optionalAttrs (sysconfig.networking.hostName == "valmar") {
            "ctrl + alt + {1,2,3,4}" = # input switching
              "/run/wrappers/bin/sudo ${ddcutil}/bin/ddcutil --bus 3 setvcp 60 0x0{1,3,4,f}";
            "ctrl + alt + 0" = concatStringsSep " && " [
              # turn off display
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
      stereo = Upstairs Stereo
    '';

    "libvirt/libvirt.conf".text = ''
      uri_default='qemu:///system'
    '';
  };
}
