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
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          antyos.openscad
          editorconfig.editorconfig
          github.copilot
          github.copilot-chat
          graphql.vscode-graphql
          jdinhlife.gruvbox
          jebbs.plantuml
          jnoortheen.nix-ide
          llvm-vs-code-extensions.vscode-clangd
          mkhl.direnv
          ms-azuretools.vscode-docker
          ms-python.python
          rust-lang.rust-analyzer
          tamasfe.even-better-toml
          vscodevim.vim

          # Elm
          elmtooling.elm-ls-vscode
          hbenl.vscode-test-explorer
          ms-vscode.test-adapter-converter
        ];
        userSettings = {
          "editor.fontFamily" = "'Hack Nerd Font', 'monospace', monospace, 'Droid Sans Fallback'";
          "editor.formatOnSave" = true;
          "editor.renderControlCharacters" = true;
          "editor.renderWhitespace" = "boundary";
          "editor.wordWrap" = "on";
          "files.insertFinalNewline" = true;
          "telemetry.telemetryLevel" = "off";
          "update.mode" = "none";
          "vim.useCtrlKeys" = false;
          "workbench.colorTheme" = "Gruvbox Dark Medium";

          # C++
          "clangd.path" = lib.getExe' pkgs.clang-tools "clangd";

          # Rust
          "rust-analyzer.rustfmt.overrideCommand" = [(lib.getExe pkgs.rustPackages.rustfmt)];

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
  };
}
