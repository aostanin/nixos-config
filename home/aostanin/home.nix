{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:
with lib; {
  imports =
    [
      ./fish
      ./git
      ./mpd
      ./neovim
      ./ssh
      ./tmux
      ./zsh
    ]
    ++ optional (pathExists (./hosts + "/${osConfig.networking.hostName}/home.nix")) (./hosts + "/${osConfig.networking.hostName}/home.nix")
    ++ optionals osConfig.localModules.desktop.enable [
      ./3dprinting
      ./android
      ./chromium
      ./electronics
      ./firefox
      ./foot
      ./gnupg
      ./gtk
      ./kanshi
      ./obs-studio
      ./qt
      ./sway
      ./syncthing
      ./vscode

      #  ./dunst
    ];

  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs/config.nix;
  xdg.configFile."nixpkgs/overlays.nix".source = ./nixpkgs/overlays.nix;

  home = {
    stateVersion = osConfig.system.stateVersion;

    packages = with pkgs;
      [
        bat
        beets
        bottom
        btop
        catt
        cksfv
        ctop
        dhex
        eza
        fd
        ffmpeg
        github-cli
        gitui
        gpsbabel
        httm
        jq
        lazygit
        lftp
        lsix
        minicom
        miniserve
        mqttui
        nsz
        (p7zip.override {enableUnfree = true;})
        personal-scripts
        powertop
        pv
        python3
        ranger
        rclone
        ripgrep
        sshfs
        tealdeer
        tig
        tmuxp
        tokei
        tuir
        wol
        yt-dlp
      ]
      ++ optionals osConfig.localModules.desktop.enable [
        # GUI
        audacity
        bitwarden
        etcher
        filezilla
        gimp
        gparted
        gtkpod
        jellyfin-media-player
        krita
        libreoffice
        logseq
        moonlight-qt
        mullvad-vpn
        peek
        qdirstat
        sonixd
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

        # Chat
        discord
        schildichat-desktop
        skypeforlinux
        slack
        zoom-us

        # Plasma
        (ark.override {unfreeEnableUnrar = true;})
        gwenview
        kate
        krdc
        okular
        spectacle
      ]
      ++ optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [
        nvtop
        steam-run
      ]
      ++ optionals (elem "amdgpu" osConfig.services.xserver.videoDrivers) [
        radeontop
      ]
      ++ optionals (
        (pkgs.stdenv.hostPlatform.system != "aarch64-linux")
        && (elem "modesetting" osConfig.services.xserver.videoDrivers)
      ) [
        intel-gpu-tools
      ];

    sessionVariables = {
      BROWSER = "firefox";
      EDITOR = "vi";
      VISUAL = config.home.sessionVariables.EDITOR;
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
      MANROFFOPT = "-c";
    };
  };

  programs =
    {
      broot = {
        enable = true;
        settings.modal = true;
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      starship.enable = true;

      zoxide.enable = true;
    }
    // optionalAttrs osConfig.localModules.desktop.enable {
      mpv = {
        enable = true;
        package = pkgs.mpv-unwrapped.override {ffmpeg = pkgs.ffmpeg.override {withV4l2 = true;};};
      };
    };

  services =
    {}
    // optionalAttrs osConfig.localModules.desktop.enable {
      blueman-applet.enable = true;

      mpris-proxy.enable = true;
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
}
