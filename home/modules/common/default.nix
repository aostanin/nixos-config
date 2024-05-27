{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.common;
in {
  options.localModules.common = {
    enable = mkEnableOption "common";
  };

  config = mkIf cfg.enable {
    localModules = {
      git.enable = lib.mkDefault true;
      neovim.enable = lib.mkDefault true;
      ssh.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      zsh.enable = lib.mkDefault true;
    };

    home = {
      packages = with pkgs;
        [
          bat
          btop
          cksfv
          ctop
          fd
          ffmpeg
          github-cli
          gitui
          gpsbabel
          jq
          lazygit
          lf
          lftp
          lsix
          minicom
          miniserve
          mqttui
          nsz
          ollama
          (p7zip.override {enableUnfree = true;})
          pv
          python3
          rclone
          ripgrep
          sshfs
          tealdeer
          tig
          tmuxp
          tokei
          tuir
          yt-dlp
        ]
        ++ optionals (!pkgs.stdenv.isDarwin) [
          # Not available on Darwin
          appimage-run
          dhex
          httm
          personal-scripts
          powertop
          wol
        ]
        ++ optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
          beets # broken on aarch64

          # TODO: This is huge. Don't build on VPS.
          steam-run
        ];

      sessionVariables = {
        EDITOR = "vi";
        VISUAL = config.home.sessionVariables.EDITOR;
        MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
        MANROFFOPT = "-c";
      };
    };

    programs = {
      # TODO: Broken on Darwin?
      broot = mkIf (!pkgs.stdenv.isDarwin) {
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
