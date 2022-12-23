{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions;
      [
        antyos.openscad
        bbenoist.nix
        editorconfig.editorconfig
        jdinhlife.gruvbox
        ms-azuretools.vscode-docker
        ms-python.python
        vscodevim.vim
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-direnv";
          publisher = "Rubymaniac";
          version = "0.0.2";
          sha256 = "1gml41bc77qlydnvk1rkaiv95rwprzqgj895kxllqy4ps8ly6nsd";
        }
      ];
    userSettings = {
      "editor.fontFamily" = "'Hack Nerd Font', 'monospace', monospace, 'Droid Sans Fallback'";
      "editor.minimap.enabled" = false;
      "editor.renderControlCharacters" = true;
      "editor.renderWhitespace" = "boundary";
      "editor.wordWrap" = "on";
      "files.insertFinalNewline" = true;
      "telemetry.enableTelemetry" = false;
      "telemetry.enableCrashReporter" = false;
      "update.mode" = "none";
      "vim.useCtrlKeys" = false;
      "workbench.colorTheme" = "Gruvbox Dark Medium";

      # Workaround for terminal not working https://github.com/NixOS/nixpkgs/issues/181610
      "terminal.integrated.shellIntegration.enabled" = false;
    };
  };
}
