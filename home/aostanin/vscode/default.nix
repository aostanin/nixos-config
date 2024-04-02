{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      antyos.openscad
      bbenoist.nix
      editorconfig.editorconfig
      elmtooling.elm-ls-vscode
      jdinhlife.gruvbox
      mkhl.direnv
      ms-azuretools.vscode-docker
      ms-python.python
      vscodevim.vim

      # Used by elm-ls-vscode but not packaged
      (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-test-explorer";
          publisher = "hbenl";
          version = "2.21.1";
          sha256 = "sha256-BqKSvSL93o00fksumkoY6WUvrhRqxjkBt2a1XwJIQXA=";
        };
      })
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
}
