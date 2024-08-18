{config, ...}: {
  localModules.containers = {
    defaultStoragePath = "${config.home.homeDirectory}/storage";
    defaultBulkStoragePath = "${config.home.homeDirectory}/bulk";

    containers = {
      whoami.enable = true;
    };
  };
}
