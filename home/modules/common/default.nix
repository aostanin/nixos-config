{
  lib,
  pkgs,
  config,
  nixpkgsConfig,
  ...
}: let
  cfg = config.localModules.common;
in {
  options.localModules.common = {
    enable = lib.mkEnableOption "common";

    minimal = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Don't install some optional packages.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      git.enable = lib.mkDefault true;
      neovim.enable = lib.mkDefault true;
      ssh.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      zsh.enable = lib.mkDefault true;
    };

    nixpkgs.config = import nixpkgsConfig;
    xdg.configFile."nixpkgs/config.nix".source = nixpkgsConfig;

    home = {
      packages = with pkgs;
        [
          bat
          btop
          cksfv
          ctop
          fd
          gitui
          jq
          lazygit
          lf
          lftp
          lsix
          minicom
          miniserve
          mqttui
          (p7zip.override {enableUnfree = true;})
          pv
          python3
          rclone
          ripgrep
          sshfs
          tig
          tmuxp
        ]
        ++ lib.optionals (!pkgs.stdenv.isDarwin) [
          dhex
          httm
          personal-scripts
          powertop
          wol
        ]
        ++ lib.optionals (!cfg.minimal) [
          ffmpeg
          github-cli
          gpsbabel
          nsz
          ollama
          tealdeer
          tokei
          tuir
          yt-dlp
        ]
        ++ lib.optionals (!cfg.minimal && pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
          beets # broken on aarch64
          steam-run
        ];

      sessionVariables = {
        EDITOR = "vi";
        VISUAL = config.home.sessionVariables.EDITOR;
        MANPAGER = "sh -c 'col -bx | ${lib.getExe pkgs.bat} -l man -p'";
        MANROFFOPT = "-c";
      };
    };

    programs = {
      # TODO: Broken on Darwin?
      broot = lib.mkIf (!pkgs.stdenv.isDarwin) {
        enable = true;
        settings.modal = true;
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      lsd = {
        enable = true;
        enableAliases = true;
      };

      starship.enable = true;

      zoxide.enable = true;
    };

    xdg.configFile = {
      "libvirt/libvirt.conf".text = ''
        uri_default='qemu:///system'
      '';
    };
  };
}
