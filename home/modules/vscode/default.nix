{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.vscode;
in {
  options.localModules.vscode = {
    enable = lib.mkEnableOption "vscode";
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        antyos.openscad
        editorconfig.editorconfig
        jdinhlife.gruvbox
        jnoortheen.nix-ide
        mkhl.direnv
        ms-azuretools.vscode-docker
        ms-python.python
        rust-lang.rust-analyzer
        vscodevim.vim

        # Elm
        elmtooling.elm-ls-vscode
        hbenl.vscode-test-explorer
        ms-vscode.test-adapter-converter
      ];
      userSettings = {
        "editor.fontFamily" = "'Hack Nerd Font', 'monospace', monospace, 'Droid Sans Fallback'";
        "editor.renderControlCharacters" = true;
        "editor.renderWhitespace" = "boundary";
        "editor.wordWrap" = "on";
        "files.insertFinalNewline" = true;
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";
        "vim.useCtrlKeys" = false;
        "workbench.colorTheme" = "Gruvbox Dark Medium";

        # Workaround for terminal not working https://github.com/NixOS/nixpkgs/issues/181610
        "terminal.integrated.shellIntegration.enabled" = false;

        # Elm
        "elmLS.elmPath" = lib.getExe pkgs.elmPackages.elm;
        "elmLS.elmReviewPath" = lib.getExe' pkgs.elmPackages.elm-review "elm-review";
        "elmLS.elmFormatPath" = lib.getExe pkgs.elmPackages.elm-format;
        "elmLS.elmTestPath" = lib.getExe' pkgs.elmPackages.elm-test "elm-test";

        # Nix
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = lib.getExe pkgs.nil;
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {"command" = [(lib.getExe pkgs.alejandra)];};
          };
        };
      };
    };
  };
}
