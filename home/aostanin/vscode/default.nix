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
      jdinhlife.gruvbox
      mkhl.direnv
      ms-azuretools.vscode-docker
      ms-python.python
      vscodevim.vim
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
      "telemetry.telemetryLevel" = "off";
      "update.mode" = "none";
      "vim.useCtrlKeys" = false;
      "workbench.colorTheme" = "Gruvbox Dark Medium";

      # Workaround for terminal not working https://github.com/NixOS/nixpkgs/issues/181610
      "terminal.integrated.shellIntegration.enabled" = false;
    };
  };
}
