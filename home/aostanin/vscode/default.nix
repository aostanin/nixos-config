{ pkgs, config, lib, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      ms-python.python
      vscodevim.vim
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "EditorConfig";
        publisher = "EditorConfig";
        version = "0.14.4";
        sha256 = "0580dsxhw78qgds9ljvzsqqkd2ndksppk7l9s5gnrddirn6fdk5i";
      }
      {
        name = "gruvbox-themes";
        publisher = "tomphilbin";
        version = "1.0.0";
        sha256 = "0xykf120j27s0bmbqj8grxc79dzkh4aclgrpp1jz5kkm39400z0f";
      }
      {
        name = "vscode-direnv";
        publisher = "Rubymaniac";
        version = "0.0.2";
        sha256 = "1gml41bc77qlydnvk1rkaiv95rwprzqgj895kxllqy4ps8ly6nsd";
      }
      {
        name = "vscode-docker";
        publisher = "ms-azuretools";
        version = "1.0.0";
        sha256 = "1zljdgym3kz4plb2a3z0yxvpqf4lnf215rajjs5sr7dxx3dwrxdg";
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
      "workbench.colorTheme" = "Gruvbox Dark (Medium)";

      # Workaround for terminal not working https://github.com/NixOS/nixpkgs/issues/181610
      "terminal.integrated.shellIntegration.enabled" = false;
    };
  };
}
