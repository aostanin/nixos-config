{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned off nixos-26.05: 1bc55b9 (2026-09-22) ships podman 5.8.7, which
    # rejects the forgejo runner's copy into /var/run/act and fails every CI job
    # in under ten seconds at actions/checkout. 6aefcda is the last revision this
    # host ran green. Unpin once podman is fixed upstream or the mount changes.
    nixpkgs.url = "github:NixOS/nixpkgs/6aefcda9401be8acc2b74244fb3b37520ea1f0a8";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-kdeconnect = {
      url = "github:imshuhao/homebrew-kdeconnect";
      flake = false;
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko-zfs = {
      url = "github:numtide/disko-zfs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
      inputs.flake-parts.follows = "flake-parts";
    };
    impermanence.url = "github:nix-community/impermanence";
    nixos-artwork = {
      url = "github:NixOS/nixos-artwork";
      flake = false;
    };
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    nixos-sbc.url = "github:aostanin/nixos-sbc/r3-mini";
    kvmd.url = "github:aostanin/kvmd.nix";
    terranix.url = "github:terranix/terranix";
    llm-agents.url = "github:numtide/llm-agents.nix";
    maki.url = "github:tontinton/maki";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    paneru = {
      # On testing for the window-rule width fix; back to main once it lands there.
      # https://github.com/karinushka/paneru/commit/b93560b86da001d239d46de3498ec42ff5f25d7c
      url = "github:karinushka/paneru/testing";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nur,
    deploy-rs,
    flake-parts,
    ...
  }: let
    lib = nixpkgs.lib;
    secrets = import ./secrets;
    sopsFiles = {
      default = ./secrets/sops/secrets.enc.yaml;
      terranix = ./secrets/sops/terranix.enc.yaml;
    };
    hosts = {
      andreis-macbook-pro = {system = "aarch64-darwin";};
      dev = {
        system = "x86_64-linux";
        containerHost = "elena";
      };
      elena = {system = "x86_64-linux";};
      every-router = {
        system = "aarch64-linux";
        additionalModules = [
          inputs.nixos-sbc.nixosModules.default
          inputs.nixos-sbc.nixosModules.boards.bananapi.bpir3mini
        ];
      };
      mac-vm = {system = "x86_64-darwin";};
      mareg = {system = "x86_64-linux";};
      octopi = {system = "aarch64-linux";};
      pikvm = {
        system = "aarch64-linux";
        additionalModules = [
          inputs.kvmd.nixosModules.kvmd
          inputs.kvmd.nixosModules.v2-hdmi-rpi4
          inputs.kvmd.inputs.nixos-raspberrypi.lib.inject-overlays
          {_module.args.nixos-raspberrypi = inputs.kvmd.inputs.nixos-raspberrypi;}
        ];
      };
      roan = {system = "x86_64-linux";};
      router = {
        system = "x86_64-linux";
        additionalModules = [inputs.microvm.nixosModules.microvm];
        microvmHost = "elena";
      };
      skye = {system = "x86_64-linux";};
      macnix = {system = "aarch64-linux";};
      vps-oci1 = {system = "x86_64-linux";};
      vps-oci2 = {system = "x86_64-linux";};
      vps-oci-arm1 = {system = "aarch64-linux";};
    };
    nixpkgsConfig = ./nixpkgs-config.nix;
    mkPkgs = system: rec {
      config = import nixpkgsConfig;
      overlays = [
        nur.overlays.default
        self.overlays.packages
        self.overlays.workarounds
        inputs.llm-agents.overlays.shared-nixpkgs
        (final: prev: {
          maki = inputs.maki.packages.${system}.default;
          unstable = import nixpkgs-unstable {
            inherit config system;
          };
        })
      ];
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with flake-parts.lib; let
        args = {inherit secrets sopsFiles hosts nixpkgsConfig mkPkgs;};
      in [
        (importApply ./nixos/flake-module.nix args)
        (importApply ./darwin/flake-module.nix args)
        (importApply ./home/flake-module.nix args)
        (importApply ./terranix/flake-module.nix {})
        inputs.treefmt-nix.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            attic-client
            deploy-rs.packages.${system}.default
            git-agecrypt
            sops
          ];
        };

        checks = pkgs.lib.attrsets.mergeAttrsList [
          (deploy-rs.lib.${system}.deployChecks {
            # Only check nodes with the same system
            nodes = lib.filterAttrs (n: v: hosts.${n}.system == system) self.deploy.nodes;
          })
        ];

        packages = import ./packages {inherit pkgs;};

        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            # Nix
            alejandra.enable = true;

            # Markdown, YAML, JSON
            prettier = {
              enable = true;
              includes = ["*.md" "*.yaml" "*.yml" "*.json"];
              excludes = ["secrets/sops/*.enc.yaml"];
            };

            # Shell scripts
            shfmt = {
              enable = true;
              indent_size = 2;
            };
          };
          # -ci: indent switch cases
          # -bn: binary ops like && and | may start a line
          settings.formatter.shfmt.options = lib.mkAfter ["-ci" "-bn"];
        };
      };
      flake = {
        deploy.nodes = let
          mkNode = {
            hostname,
            system,
            # A nixos-container's system is part of its host's closure.
            deploySystemProfile ? true,
          }: {
            inherit hostname;
            sshUser = secrets.user.username;
            fastConnection = false;
            autoRollback = false;
            magicRollback = false;
            remoteBuild = false;

            profiles =
              lib.optionalAttrs (deploySystemProfile && builtins.hasAttr hostname self.nixosConfigurations) {
                system = {
                  user = "root";
                  path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations."${hostname}";
                };
              }
              // lib.optionalAttrs (builtins.hasAttr hostname self.darwinConfigurations) {
                system = {
                  user = "root";
                  path = deploy-rs.lib.${system}.activate.darwin self.darwinConfigurations."${hostname}";
                };
              }
              // lib.optionalAttrs (builtins.hasAttr hostname self.homeConfigurations) {
                home = {
                  user = secrets.user.username;
                  path = deploy-rs.lib.${system}.activate.home-manager self.homeConfigurations."${hostname}";
                };
              };
          };
          # A microvm is deployed through its host: deploy-rs installs the runner
          # where microvm@<name> looks for it and restarts the VM if it changed.
          mkMicrovmNode = {
            hostname,
            system,
            microvmHost,
          }: let
            pkgs = nixpkgs.legacyPackages.${system};
            runner = self.nixosConfigurations.${hostname}.config.microvm.declaredRunner;
            stateDir = self.nixosConfigurations.${microvmHost}.config.microvm.stateDir;
          in {
            hostname = microvmHost;
            sshUser = secrets.user.username;
            fastConnection = false;
            autoRollback = false;
            magicRollback = false;
            remoteBuild = false;

            profiles.system = {
              user = "root";
              profilePath = "/nix/var/nix/profiles/microvm-${hostname}";
              path = deploy-rs.lib.${system}.activate.custom runner ''
                dir=${stateDir}/${hostname}
                mkdir -p "$dir"
                ln -sTf ${runner} "$dir/current"
                chown -h microvm:kvm "$dir" "$dir/current"
                if [ "$(readlink "$dir/booted" 2>/dev/null)" != "${runner}" ]; then
                  ${pkgs.systemd}/bin/systemctl restart microvm@${hostname}.service
                fi
              '';
            };
          };
        in (builtins.mapAttrs (hostname: host:
          if host ? microvmHost
          then
            mkMicrovmNode {
              inherit hostname;
              inherit (host) system microvmHost;
            }
          else
            mkNode {
              inherit hostname;
              inherit (host) system;
              deploySystemProfile = !(host ? containerHost);
            })
        hosts);

        overlays = {
          packages = final: prev: import ./packages {pkgs = prev;};
          workarounds = import ./overlays/workarounds.nix;
        };
      };
    };
}
