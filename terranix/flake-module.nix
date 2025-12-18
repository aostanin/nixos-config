{}: {
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: {
    apps.terraform = let
      terraform = pkgs.opentofu.withPlugins (p: [
        p.cloudflare_cloudflare
        p.hashicorp_local
        p.hashicorp_null
        p.hashicorp_random
        p.carlpett_sops
        p.tailscale_tailscale
      ]);
      terraformConfiguration = inputs.terranix.lib.terranixConfiguration {
        inherit system;
        modules = [
          ./modules
          ./config.nix
        ];
      };
    in {
      type = "app";
      program = toString (pkgs.writers.writeBash "terraform" ''
        if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
        ln -sf ${terraformConfiguration} config.tf.json
        ${lib.getExe terraform} init --upgrade
        ${lib.getExe terraform} "$@"
      '');
    };
  };
}
