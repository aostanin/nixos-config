{
  lib,
  hostname,
  secrets,
  ...
}: {
  imports = [
    ./containers
    ./networks
  ];

  options.localModules.containers = {
    host = lib.mkOption {
      type = lib.types.str;
      default = hostname;
      description = ''
        Host name.
      '';
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = secrets.domain;
      description = ''
        Domain name.
      '';
    };

    defaultStoragePath = lib.mkOption {
      type = lib.types.str;
      description = ''
        Default storage path.
      '';
    };

    defaultBulkStoragePath = lib.mkOption {
      type = lib.types.str;
      description = ''
        Default bulk storage path.
      '';
    };
  };
}
