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
          definition = domain.writeXML (import ./OpenWRT.nix args);
          restart = false;
        }
      ];

      networks = [
        {
          definition = network.writeXML {
            name = "default";
            uuid = "ec6b2484-2660-4cff-912d-72c37e61afd5";
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
            uuid = "2893512e-78fc-47ed-a2fe-f7d68d7501a3";
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
      ];
    };
  };
}
