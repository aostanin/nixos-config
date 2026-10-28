{
  lib,
  secrets,
  ...
}: {
  networking.hostName = "router";

  microvm = {
    hypervisor = "qemu";
    vcpu = 2;
    mem = 512;
    # The VM's only NIC: a trunk port on elena's br0, like the physical routers'.
    interfaces = [
      {
        type = "tap";
        id = "vm-router";
        mac = secrets.network.home.hosts.router.macAddress;
        tap.vhost = true;
      }
    ];
    volumes = [
      {
        image = "var.img";
        label = "var";
        mountPoint = "/var";
        size = 2048;
      }
    ];
    # Rescue path from the host (`ssh vsock/42`) when the LAN side is broken.
    vsock = {
      cid = 42;
      ssh.enable = true;
    };
  };

  # The conntrack table is otherwise sized from RAM, which is small here. An
  # explicit hashsize sets nf_conntrack_max to 8x it (32768); a module option
  # because a sysctl can run before nftables loads the module.
  boot.extraModprobeConfig = "options nf_conntrack hashsize=4096";

  # Root is tmpfs; keep the identity on the /var volume, mounted early enough
  # for sops to decrypt with the host key during activation.
  environment.etc.machine-id.text = "8d1c0e7f3a5b4c2e9f6a1d3b5c7e9f02\n";
  # The ID lives in the store, so systemd overmounts a transient copy and the
  # commit can only fail writing it back. Same unit as
  # https://github.com/nix-community/impermanence/issues/229.
  systemd.services.systemd-machine-id-commit.enable = false;
  fileSystems."/var".neededForBoot = true;
  sops.age.sshKeyPaths = ["/var/lib/ssh/ssh_host_ed25519_key"];
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/var/lib/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings.PasswordAuthentication = false;
  };

  users = {
    mutableUsers = false;
    users = {
      ${secrets.user.username} = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = [secrets.user.sshKey];
      };
      root.openssh.authorizedKeys.keys = [secrets.user.sshKey];
    };
  };
  security.sudo.wheelNeedsPassword = false;

  # Deploys go through the host's store; nothing is built in here.
  nix.enable = false;

  time.timeZone = "Asia/Tokyo";

  # Also serves tailnet DNS from the router's coredns.
  localModules.tailscale = {
    enable = true;
    advertiseExitNode = true;
    advertiseRoutes = ["${secrets.network.networks.iot.prefix}.0/24"];
  };

  localModules.home-router = {
    enable = true;
    interface = "enx${lib.replaceStrings [":"] [""] secrets.network.home.hosts.router.macAddress}";
    macAddress = secrets.network.home.hosts.router.macAddress;
  };
}
