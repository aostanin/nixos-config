{
  lib,
  pkgs,
  config,
  nixpkgsConfig,
  localLib,
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
      ai.enable = lib.mkDefault (!cfg.minimal);
      git.enable = lib.mkDefault true;
      neovim.enable = lib.mkDefault (!cfg.minimal);
      ssh.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      zellij.enable = lib.mkDefault (!cfg.minimal);
      zsh.enable = lib.mkDefault true;
    };

    nixpkgs.config = import nixpkgsConfig;
    xdg.configFile."nixpkgs/config.nix".source = nixpkgsConfig;

    home = {
      packages = localLib.filterAvailable (with pkgs;
        [
          bat
          btop
          cksfv
          ctop
          dhex
          fd
          gdu
          gping
          htop
          httm
          jq
          just
          lazygit
          lftp
          lsix
          minicom
          miniserve
          mqttui
          nix-tree
          (p7zip.override {enableUnfree = !cfg.minimal;})
          powertop
          pv
          python3
          rainfrog
          rclone
          ripgrep
          s-tui
          sshfs
          stress
          tig
          tio
          tmuxp
          tree
          wol
        ]
        ++ lib.optionals (!cfg.minimal) [
          unstable.devenv
          ffmpeg
          github-cli
          gpsbabel
          unstable.ollama
          steam-run
          tealdeer
          tokei
          (pkgs.writeShellScriptBin "torrent-dl" ''
            scp ~/Downloads/*.torrent elena:/storage/appdata/docker/ssd/qbittorrent/watch && rm ~/Downloads/*.torrent
          '')
          yt-dlp
        ]);

      sessionVariables = {
        MANPAGER = "sh -c 'col -bx | ${lib.getExe pkgs.bat} -l man -p'";
        MANROFFOPT = "-c";
        NIXPKGS_ALLOW_UNFREE = "1";
      };
    };

    programs = {
      broot = {
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
        enable = !cfg.minimal;
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
