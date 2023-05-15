{
  config,
  pkgs,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
  drives = [
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG052SA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TT6A"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TTLA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TV0A"
  ];
in {
  imports = [
    "${hardwareModulesPath}/raspberry-pi/4"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/zerotier
    ../../modules
  ];

  boot = {
    supportedFilesystems = ["zfs"];
  };

  networking = {
    hostName = "tio";
    hostId = "9d6a993f";
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.tio.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = secrets.network.home.nameserversAdguard;
  };

  # services.zrepl = {
  #   enable = true;
  #   settings = {
  #     jobs = [
  #       {
  #         type = "pull";
  #         name = "pull-elena";
  #         connect = {
  #           type = "tcp";
  #           address = "[${secrets.network.zerotier.hosts.elena.address6}]:8889";
  #         };
  #         recv = {
  #           placeholder.encryption = "inherit";
  #         };
  #         root_fs = "backup/backup/hosts/zfs/elena";
  #         interval = "manual";
  #         pruning = {
  #           keep_sender = [
  #             {
  #               type = "regex";
  #               regex = ".*";
  #             }
  #           ];
  #           keep_receiver = [
  #             {
  #               type = "grid";
  #               grid = "1x1h(keep=all) | 24x1h | 90x1d";
  #               regex = "^zrepl_.*";
  #             }
  #             {
  #               type = "regex";
  #               negate = true;
  #               regex = "^zrepl_.*";
  #             }
  #           ];
  #         };
  #       }
  #     ];
  #   };
  # };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  virtualisation.libvirtd = {
    enable = true;
    # viriscsitest fails
    package = pkgs.libvirt.overrideAttrs (old: {doCheck = false;});
  };

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
    # Docker defaults to Google's DNS
    extraOptions = ''
      --dns ${secrets.network.home.nameserver} \
      --dns-search lan
    '';
  };
}
