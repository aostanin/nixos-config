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
        bbenoist.nix
        editorconfig.editorconfig
        jdinhlife.gruvbox
        mkhl.direnv
        ms-azuretools.vscode-docker
        ms-python.python
        vscodevim.vim

        # Elm
        elmtooling.elm-ls-vscode
        # TODO: Move to stable
        pkgs.unstable.vscode-extensions.hbenl.vscode-test-explorer
        pkgs.unstable.vscode-extensions.ms-vscode.test-adapter-converter
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
        "elmLS.elmPath" = "${pkgs.elmPackages.elm}/bin/elm";
        "elmLS.elmReviewPath" = "${pkgs.elmPackages.elm-review}/bin/elm-review";
        "elmLS.elmFormatPath" = "${pkgs.elmPackages.elm-format}/bin/elm-format";
        "elmLS.elmTestPath" = "${pkgs.elmPackages.elm-test}/bin/elm-test";
      };
    };
  };
}