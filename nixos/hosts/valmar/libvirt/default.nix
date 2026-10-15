{
  config,
  inputs,
  ...
} @ args: let
  domain = inputs.nixvirt.lib.domain;
  network = inputs.nixvirt.lib.network;
  pool = inputs.nixvirt.lib.pool;

  imagesRoot = "/vm";
in {
  imports = [inputs.nixvirt.nixosModules.default];

  # vmpool is mounted natively (disko-config.nix), so no fileSystems entry
  # pulls in its import.
  boot.zfs.extraPools = ["vmpool"];

  virtualisation.libvirt = {
    enable = true;

    connections."qemu:///system" = {
      domains = [
        {
          definition = domain.writeXML (import ./win10-play.nix args);
          active = null;
        }
        {
          definition = domain.writeXML (import ./win10-work.nix args);
          active = null;
        }
      ];

      networks = [
        {
          # NAT until br0 exists (network.nix).
          definition = network.writeXML ({
              name = "default";
              uuid = "eb70d2b6-35a2-4206-bcbc-8eebb4b644e9";
            }
            // (
              if config.localModules.home-server.enable
              then {
                forward.mode = "bridge";
                bridge.name = "br0";
              }
              else {
                forward.mode = "nat";
                bridge.name = "virbr0";
                ip = {
                  address = "192.168.122.1";
                  netmask = "255.255.255.0";
                  dhcp.range = {
                    start = "192.168.122.2";
                    end = "192.168.122.254";
                  };
                };
              }
            ));
          active = true;
        }
      ];

      pools = [
        {
          definition = pool.writeXML {
            type = "dir";
            name = "default";
            uuid = "deb4d829-6f23-472b-a6cc-587879a064a2";
            target = {
              path = "${imagesRoot}/default";
              permissions = {
                mode.octal = "0755";
                owner.uid = 0;
                group.gid = 0;
              };
            };
          };
          active = true;
        }
        {
          definition = pool.writeXML {
            type = "dir";
            name = "isos";
            uuid = "7f86cd4e-59d2-475a-b0f9-994bd3c64281";
            target = {
              path = "${imagesRoot}/isos";
              permissions = {
                mode.octal = "0755";
                owner.uid = 0;
                group.gid = 0;
              };
            };
          };
          active = true;
        }
      ];
    };
  };
}
