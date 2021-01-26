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
  ] ++ optionals nixosConfig.services.xserver.enable [
    ./3dprinting
    ./alacritty
    ./chromium
    ./electronics
    ./firefox
    ./gnupg
    ./gtk
    ./obs-studio
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
      tealdeer
      tig
      tmuxp
      tokei
      translate-shell
      tuir
      wol
      youtube-dl
      ytop
    ] ++ optionals nixosConfig.services.xserver.enable [
      # GUI
      barrier
      bitwarden
      etcher
      filezilla
      gimp
      gparted
      jellyfin-mpv-shim
      keepassxc
      krita
      libreoffice
      peek
      steam
      syncthing-gtk
      thunderbird
      virtmanager
      virtscreen
      wineWowPackages.stable
      xclip

      # Chat
      discord
      element-desktop
      skypeforlinux
      slack
      tdesktop
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
      direnv = {
        enable = true;
        enableNixDirenvIntegration = true;
      };

      starship.enable = true;
    }
    // optionalAttrs nixosConfig.services.xserver.enable {
      mpv.enable = true;
    };

  services =
    {
      lorri.enable = true;
    }
    // optionalAttrs nixosConfig.services.xserver.enable {
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
