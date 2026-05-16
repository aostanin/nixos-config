{inputs, ...} @ args: let
  domain = inputs.nixvirt.lib.domain;
  network = inputs.nixvirt.lib.network;
  pool = inputs.nixvirt.lib.pool;
in {
  imports = [inputs.nixvirt.nixosModules.default];

  virtualisation.libvirt = {
    enable = true;

    connections."qemu:///system" = {
      domains = [
        {
          definition = domain.writeXML (import ./macos.nix args);
          active = null;
        }
        {
          definition = domain.writeXML (import ./ubuntu.nix args);
          active = null;
        }
        {
          definition = domain.writeXML (import ./win11.nix args);
          active = null;
        }
      ];

      networks = [
        {
          definition = network.writeXML {
            name = "default";
            uuid = "e146dacb-b562-4f2c-8bb9-48c3b8ed3707";
            forward.mode = "nat";
            bridge = {
              name = "virbr0";
              stp = true;
              delay = 0;
            };
            mac.address = "52:54:00:e1:d7:9c";
            ip = {
              address = "192.168.122.1";
              netmask = "255.255.255.0";
              dhcp.range = {
                start = "192.168.122.2";
                end = "192.168.122.254";
              };
            };
          };
          active = true;
        }
      ];

      pools = [
        {
          definition = pool.writeXML {
            type = "dir";
            name = "default";
            uuid = "a6aa496c-77f5-47e0-9b44-8705df69907f";
            target = {
              path = "/var/lib/libvirt/images";
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
            uuid = "a6c87b95-6e9d-45ba-9bc6-282541b16427";
            target = {
              path = "/var/lib/libvirt/images/rpool/isos";
              permissions = {
                mode.octal = "0755";
                owner.uid = 1000;
                group.gid = 100;
              };
            };
          };
          active = true;
        }
        {
          definition = pool.writeXML {
            type = "dir";
            name = "ubuntu";
            uuid = "fc190934-c994-4562-84b2-28bd36bdd610";
            target.path = "/var/lib/libvirt/images/ubuntu";
          };
          active = null;
        }
        {
          definition = pool.writeXML {
            type = "dir";
            name = "win11";
            uuid = "4f4eaef1-11f0-4ad8-87ee-25c84e4bdb95";
            target = {
              path = "/var/lib/libvirt/images/rpool/win11";
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
