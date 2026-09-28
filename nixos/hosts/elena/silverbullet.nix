{
  config,
  pkgs,
  secrets,
  ...
}: let
  port = 3300;
in {
  sops.secrets = {
    "silverbullet/password" = {};
    "silverbullet/auth_token" = {};
  };

  sops.templates."silverbullet.env".content = ''
    SB_USER=${secrets.user.username}:${config.sops.placeholder."silverbullet/password"}
    SB_AUTH_TOKEN=${config.sops.placeholder."silverbullet/auth_token"}
  '';

  services.silverbullet = {
    enable = true;
    # silverbullet-ai needs >= 2.11
    package = pkgs.unstable.silverbullet;
    listenPort = port;
    envFile = config.sops.templates."silverbullet.env".path;
  };

  # Runtime API (needed by the silverbullet-ai MCP bridge) runs the client in headless Chrome
  systemd.services.silverbullet = {
    environment = {
      SB_CHROME_PATH = "${pkgs.chromium}/bin/chromium";
      # The user's home is /var/empty; Chrome's crashpad aborts without a writable one
      HOME = "/var/cache/silverbullet";
    };
    serviceConfig.CacheDirectory = "silverbullet";
  };

  localModules.ingress.silverbullet.port = port;
}
