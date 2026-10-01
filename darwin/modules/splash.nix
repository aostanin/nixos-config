{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.splash;

  stateDir = "/var/lib/splash";
  cacheDir = "/var/cache/splash";
  logDir = "/var/log/splash";

  serveArgs =
    [
      (lib.getExe cfg.package)
      "serve"
      "--model"
      cfg.model
      "--host"
      cfg.host
      "--port"
      (toString cfg.port)
    ]
    ++ lib.optionals (cfg.revision != null) ["--revision" cfg.revision]
    ++ lib.concatMap (host: ["--allowed-host" host]) cfg.allowedHosts
    ++ cfg.extraFlags;

  # Read the key at launch: a launchd EnvironmentVariables entry would bake
  # the secret into the world-readable plist in the store.
  launchScript = pkgs.writeShellScript "splash-launch" ''
    ${lib.optionalString (cfg.apiKeyFile != null) ''
      SPLASH_API_KEY="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg cfg.apiKeyFile})"
      export SPLASH_API_KEY
    ''}
    exec ${lib.escapeShellArgs serveArgs}
  '';
in {
  options.localModules.splash = {
    enable = lib.mkEnableOption "Splash inference server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.splash;
      defaultText = lib.literalExpression "pkgs.splash";
      description = "Splash package to use.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      example = "owner/model-GGUF:UD-Q4_K_M";
      description = "Hugging Face model, with a GGUF variant after ':'.";
    };

    revision = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Model branch, tag or commit; pinning a commit skips the Hub lookup on start.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address Splash listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port Splash listens on.";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/splash/api_key";
      description = "File holding the API key clients must send as a bearer token.";
    };

    allowedHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["myhost.local"];
      description = "HTTP Host names accepted besides IP addresses and localhost.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--max-context" "128K"];
      description = "Extra flags passed to splash serve.";
    };

    wakeOnRequest = lib.mkEnableOption ''
      waking the Mac from sleep for requests: the port is advertised over
      Bonjour, so a connection to it wakes the Mac, which then stays awake
      while Splash is busy
    '';
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    system.activationScripts.preActivation.text = ''
      mkdir -p ${stateDir} ${cacheDir} ${logDir}
    '';

    launchd.daemons.splash = {
      command = "${launchScript}";

      serviceConfig = {
        Label = "org.nixos.splash";
        # Models, agent sessions and prepared weights live under HOME/Library.
        EnvironmentVariables = {
          HOME = stateDir;
          HF_HUB_CACHE = cacheDir;
        };
        WorkingDirectory = stateDir;
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${logDir}/splash.log";
        StandardErrorPath = "${logDir}/splash.log";
      };
    };

    # The Wi-Fi chip's sleep proxy only wakes the Mac for TCP SYNs to ports of
    # registered Bonjour services.
    launchd.daemons.splash-bonjour = lib.mkIf cfg.wakeOnRequest {
      command = lib.escapeShellArgs ["/usr/bin/dns-sd" "-R" "Splash" "_http._tcp" "local" (toString cfg.port)];
      serviceConfig = {
        Label = "org.nixos.splash-bonjour";
        KeepAlive = true;
        RunAtLoad = true;
      };
    };

    launchd.daemons.splash-keepawake = lib.mkIf cfg.wakeOnRequest {
      command = lib.escapeShellArgs ([
          (lib.getExe pkgs.python3)
          (pkgs.writeText "splash-keepawake.py" (builtins.readFile ./splash-keepawake.py))
          "http://127.0.0.1:${toString cfg.port}"
        ]
        ++ lib.optional (cfg.apiKeyFile != null) cfg.apiKeyFile);
      serviceConfig = {
        Label = "org.nixos.splash-keepawake";
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${logDir}/keepawake.log";
        StandardErrorPath = "${logDir}/keepawake.log";
      };
    };
  };
}
