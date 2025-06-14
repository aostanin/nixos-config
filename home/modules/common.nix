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
      zellij.enable = lib.mkDefault true;
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
          claude-code
          ctop
          fd
          gdu
          gitui
          gping
          jq
          just
          lazygit
          lftp
          lsix
          minicom
          miniserve
          mqttui
          nix-tree
          (p7zip.override {enableUnfree = true;})
          pv
          python3
          rainfrog
          rclone
          ripgrep
          sshfs
          stress
          tig
          tmuxp
        ]
        ++ lib.optionals (!pkgs.stdenv.isDarwin) [
          dhex
          httm
          personal-scripts
          powertop
          s-tui
          wol
        ]
        ++ lib.optionals (!cfg.minimal) [
          ffmpeg
          github-cli
          gpsbabel
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
        MANPAGER = "sh -c 'col -bx | ${lib.getExe pkgs.bat} -l man -p'";
        MANROFFOPT = "-c";
        NIXPKGS_ALLOW_UNFREE = "1";
      };
    };

    programs = {
      # Broken on Darwin
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
        enableZshIntegration = true;
      };

      starship.enable = true;

      yazi = {
        enable = true;
        enableZshIntegration = true;
      };

      zoxide.enable = true;
    };

    xdg.configFile = {
      "libvirt/libvirt.conf".text = ''
        uri_default='qemu:///system'
      '';
    };

    home.file = {
      ".cargo/config.toml".text = ''
        [net]
        git-fetch-with-cli = true
      '';
    };
  };
}
