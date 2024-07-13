{
  # TODO: Make flake module and merge with parent flake
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    terranix.url = "github:terranix/terranix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    terranix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      terraform = pkgs.opentofu;
      terraformConfiguration = terranix.lib.terranixConfiguration {
        inherit system;
        modules = [
          ./modules
          ./config.nix
        ];
      };
    in {
      defaultPackage = terraformConfiguration;

      devShell = pkgs.mkShell {
        buildInputs = [
          terraform
          terranix.defaultPackage.${system}
        ];
      };

      apps.terraform = {
        type = "app";
        program = toString (pkgs.writers.writeBash "terraform" ''
          if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
          cp ${terraformConfiguration} config.tf.json
          ${terraform}/bin/tofu init
          ${terraform}/bin/tofu "$@"
        '');
      };

      defaultApp = self.apps.${system}.terraform;

      formatter = pkgs.alejandra;
    });
}
