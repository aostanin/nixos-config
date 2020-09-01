{ pkgs, config, lib, ... }:

with lib;
let
  secrets = import ../../../secrets;
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings

      ${optionalString pkgs.stdenv.isDarwin ''
      set -gx HOMEBREW_GITHUB_API_TOKEN=${secrets.githubApiToken}
      ''}
    '';
  };
}
