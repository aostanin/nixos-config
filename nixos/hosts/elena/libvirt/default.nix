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
          definition = network.writeXML {
            name = "default";
            uuid = "eb70d2b6-35a2-4206-bcbc-8eebb4b644e9";
            forward.mode = "bridge";
            bridge.name = "br0";
          };
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
              path = "/var/lib/libvirt/images/vmpool/default";
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
              path = "/var/lib/libvirt/images/vmpool/isos";
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
