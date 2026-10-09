{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.llamaSwap;

  stateDir = "/var/lib/llama-swap";
  logDir = "/var/log/llama-swap";

  configFile = (pkgs.formats.yaml {}).generate "llama-swap.yaml" (
    cfg.settings
    // lib.optionalAttrs (cfg.apiKeyFile != null) {apiKeys = ["\${env.LLAMA_SWAP_API_KEY}"];}
  );

  # Read the key at launch: a launchd EnvironmentVariables entry would bake
  # the secret into the world-readable plist in the store.
  launchScript = pkgs.writeShellScript "llama-swap-launch" ''
    ${lib.optionalString (cfg.apiKeyFile != null) ''
      LLAMA_SWAP_API_KEY="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg cfg.apiKeyFile})"
      export LLAMA_SWAP_API_KEY
    ''}
    exec ${lib.getExe cfg.package} --config ${configFile} --listen ${cfg.host}:${toString cfg.port}
  '';
in {
  options.localModules.llamaSwap = {
    enable = lib.mkEnableOption "llama-swap";

    package = lib.mkPackageOption pkgs "llama-swap" {};

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/llama-swap/api_key";
      description = "File holding the API key clients must send as a bearer token.";
    };

    settings = lib.mkOption {
      type = (pkgs.formats.yaml {}).type;
      default = {};
      description = "llama-swap configuration; `apiKeys` is set from `apiKeyFile`.";
    };

    wakeOnRequest = lib.mkEnableOption ''
      waking the Mac from sleep for requests: the port is advertised over
      Bonjour, so a connection to it wakes the Mac, which then stays awake
      while requests are in flight
    '';
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.preActivation.text = ''
      mkdir -p ${stateDir} ${logDir}
    '';

    launchd.daemons.llama-swap = {
      command = "${launchScript}";
      serviceConfig = {
        Label = "org.nixos.llama-swap";
        WorkingDirectory = stateDir;
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${logDir}/llama-swap.log";
        StandardErrorPath = "${logDir}/llama-swap.log";
      };
    };

    # The Wi-Fi chip's sleep proxy only wakes the Mac for TCP SYNs to ports of
    # registered Bonjour services.
    launchd.daemons.llama-swap-bonjour = lib.mkIf cfg.wakeOnRequest {
      command = lib.escapeShellArgs ["/usr/bin/dns-sd" "-R" "llama-swap" "_http._tcp" "local" (toString cfg.port)];
      serviceConfig = {
        Label = "org.nixos.llama-swap-bonjour";
        KeepAlive = true;
        RunAtLoad = true;
      };
    };

    launchd.daemons.llama-swap-keepawake = lib.mkIf cfg.wakeOnRequest {
      command = lib.escapeShellArgs ([
          (lib.getExe pkgs.python3)
          (pkgs.writeText "llama-swap-keepawake.py" (builtins.readFile ./llama-swap-keepawake.py))
          "http://127.0.0.1:${toString cfg.port}"
        ]
        ++ lib.optional (cfg.apiKeyFile != null) cfg.apiKeyFile);
      serviceConfig = {
        Label = "org.nixos.llama-swap-keepawake";
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${logDir}/keepawake.log";
        StandardErrorPath = "${logDir}/keepawake.log";
      };
    };
  };
}
