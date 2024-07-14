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
      lib = pkgs.lib;
      terraform = pkgs.opentofu.withPlugins (p: [
        p.cloudflare
        p.local
        p.null
        p.random
        p.tailscale
      ]);
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
          ln -sf ${terraformConfiguration} config.tf.json
          ${lib.getExe terraform} init
          ${lib.getExe terraform} "$@"
        '');
      };

      defaultApp = self.apps.${system}.terraform;

      formatter = pkgs.alejandra;
    });
}
