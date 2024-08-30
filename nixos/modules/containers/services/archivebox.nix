{
  lib,
  config,
  ...
}: let
  name = "archivebox";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/archivebox/archivebox:master";
      raw.cmd = ["server" "--quick-init" "0.0.0.0:8000"];
      raw.environment = let
        userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36";
      in {
        SAVE_ARCHIVE_DOT_ORG = "False";
        PUBLIC_INDEX = "False";
        PUBLIC_SNAPSHOTS = "False";
        PUBLIC_ADD_VIEW = "False";
        CURL_USER_AGENT = userAgent;
        WGET_USER_AGENT = userAgent;
        CHROME_USER_AGENT = userAgent;
      };
      volumes.data.destination = "/data";
      proxy = {
        enable = true;
        port = 8000;
      };
    };
  };
}
