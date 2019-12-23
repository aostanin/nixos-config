{ pkgs, config, lib, ... }:

with lib;

let
  sysconfig = (import <nixpkgs/nixos> {}).config;
in {
  nixpkgs.config = import ./nixpkgs/config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs/config.nix;

  nixpkgs.overlays = import ./nixpkgs/overlays.nix;
  xdg.configFile."nixpkgs/overlays.nix".source = ./nixpkgs/overlays.nix;

  home = {
    packages = with pkgs; [
      bat
      catt
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
      pidcat
      scrcpy
    ];

    sessionVariables = {
      EDITOR = "vi";
      VISUAL = config.home.sessionVariables.EDITOR;
      MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
    };
  };

  programs = {
    direnv.enable = true;

    git = {
      enable = true;
      userName = "***REMOVED***";
      userEmail = "***REMOVED***";
      ignores = [
        # Compiled source
        "*.com"
        "*.class"
        "*.dll"
        "*.exe"
        "*.o"
        "*.so"
        "*.pyc"

        # OS generated files
        ".DS_Store"
        "Thumbs.db"

        # Other SCM
        ".svn"

        # Junk files
        "*.bak"
        "*.swp"
        "*~"

        # IDE
        ".idea"
        "*.iml"
        ".vscode"

        # SyncThing
        ".stfolder"
        ".stignore"
      ];
    };

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

    starship.enable = true;

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

    zsh = {
      enable = true;
      enableAutosuggestions = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "vi-mode"
        ];
      };
      initExtra = ''
        autoload zmv
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        export PATH=$HOME/.local/bin:$PATH
      '';
      localVariables = {
        CASE_SENSITIVE = "true";
        DISABLE_AUTO_UPDATE = "true";
      } // optionalAttrs pkgs.stdenv.isDarwin {
        HOMEBREW_GITHUB_API_TOKEN = "***REMOVED***";
      };
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
    lorri.enable = true;
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

  home.file = {
    ".ssh/config".source = ./ssh_config;
    ".ssh/master/.keep".text = "";
  } // optionalAttrs sysconfig.services.xserver.enable {
    ".local/share/konsole/Gruvbox_dark.colorscheme".source = ./konsole/Gruvbox_dark.colorscheme;
    ".local/share/konsole/Profile 1.profile".source = ./konsole/Profile_1.profile;
  };
}
