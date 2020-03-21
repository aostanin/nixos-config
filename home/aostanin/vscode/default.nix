{ pkgs, config, lib, ... }:

{
  programs.vscode = {
    enable = true;
    # TODO: Requires master home-manager
    # package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.Nix
      pkgs.unstable.vscode-extensions.ms-python.python # TODO: stable had a 404
      vscodevim.vim
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
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
    };
  };
}
