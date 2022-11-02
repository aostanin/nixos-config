{ pkgs, config, lib, nixosConfig, ... }:

with lib;

{
  imports = [
    ./fish
    ./git
    ./mpd
    ./neovim
    ./ssh
    ./tmux
    ./zsh
  ] ++ optionals nixosConfig.variables.hasDesktop [
    ./3dprinting
    ./alacritty
    ./chromium
    ./electronics
    ./firefox
    ./gnupg
    ./gtk
    ./obs-studio
    ./qt
    ./syncthing
    ./vscode
  ] ++ optionals nixosConfig.services.xserver.windowManager.i3.enable [
    ./autorandr
    ./dunst
    ./i3
  ] ++ optionals nixosConfig.programs.adb.enable [
    ./android
  ];

  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs/config.nix;
  xdg.configFile."nixpkgs/overlays.nix".source = ./nixpkgs/overlays.nix;

  home = {
    stateVersion = nixosConfig.system.stateVersion;

    packages = with pkgs; [
      bat
      beets
      bottom
      btop
      catt
      cksfv
      nur.repos.xe.comma
      ctop
      dhex
      exa
      fd
      ffmpeg
      github-cli
      gitui
      gpsbabel
      httm
      ipmitool
      lazygit
      lftp
      miniserve
      nsz
      (p7zip.override { enableUnfree = true; })
      personal-scripts
      pv
      python3
      ranger
      rclone
      ripgrep
      tealdeer
      tig
      tmuxp
      tokei
      translate-shell
      tuir
      wol
      yt-dlp
    ] ++ optionals nixosConfig.variables.hasDesktop [
      # GUI
      barrier
      bitwarden
      etcher
      filezilla
      gimp
      gparted
      gtkpod
      jellyfin-media-player
      keepassxc
      krita
      libreoffice
      moonlight-qt
      mullvad-vpn
      peek
      qdirstat
      steam
      (sublime-music.override { chromecastSupport = true; })
      thunderbird
      virtmanager
      virtscreen
      wineWowPackages.stable
      xclip

      # Chat
      discord
      schildichat-desktop
      skypeforlinux
      slack
      zoom-us

      # Plasma
      (ark.override { unfreeEnableUnrar = true; })
      gwenview
      kate
      krdc
      okular
      spectacle
    ] ++ optionals (elem "amdgpu" nixosConfig.services.xserver.videoDrivers) [
      radeontop
    ] ++ optionals (elem "intel" nixosConfig.services.xserver.videoDrivers) [
      intel-gpu-tools
    ] ++ optionals (elem "nvidia" nixosConfig.services.xserver.videoDrivers) [
      nvtop
    ];

    sessionVariables = {
      BROWSER = "firefox";
      EDITOR = "vi";
      VISUAL = config.home.sessionVariables.EDITOR;
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
    };
  };

  programs =
    {
      broot = {
        enable = true;
        modal = true;
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      starship.enable = true;

      zoxide.enable = true;
    }
    // optionalAttrs nixosConfig.variables.hasDesktop {
      mpv.enable = true;
    };

  services =
    { }
    // optionalAttrs nixosConfig.variables.hasDesktop {
      blueman-applet.enable = true;

      mpris-proxy.enable = true;

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
          };
      };

      xcape.enable = true;
    };

  xdg.configFile = {
    "catt/catt.cfg".text = ''
      [options]
      device = bedroom

      [aliases]
      kitchen = Kitchen Home Hub Max
      bedroom = Bedroom TV
    '';

    "libvirt/libvirt.conf".text = ''
      uri_default='qemu:///system'
    '';
  };

  xsession.enable = true;
}
