{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.ssh;
in {
  options.localModules.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."pikvm/password" = {};

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "*".extraOptions.StrictHostKeyChecking = "no";

        "git.${secrets.domain}" = {
          hostname = "roan";
          port = 2222;
          user = "git";
        };

        elena = let
          wake = let
            inherit (secrets.pikvm) baseUrl username;
            passwordFile = config.sops.secrets."pikvm/password".path;
          in
            # TODO: Make module
            pkgs.writeShellScript "wake-elena" ''
              ssh_available()
              {
                nc -zw3 elena 22 > /dev/null 2>&1
              }

              is_on()
              {
                curl -s -k -u "${username}:$(cat ${passwordFile})" "${baseUrl}/api/gpio" | \
                  ${lib.getExe pkgs.jq} -e '.result.state.inputs.atx1_power_led.state == true'
              }

              toggle_power()
              {
                curl -X POST -s -k -o /dev/null -u "${username}:$(cat ${passwordFile})" "${baseUrl}/api/gpio/pulse?channel=atx1_power_button"
              }

              wait_on()
              {
                until ssh_available; do sleep 1; done
              }

              if ssh_available; then
                exit 0
              fi

              if ! is_on; then
                toggle_power
                wait_on
              fi
            '';
        in {
          match = "host elena exec \"${wake} %h\"";
        };

        octopi.user = "pi";

        pikvm.user = "root";
      };
    };

    # Avoid SSH persmission issues
    # ref: https://github.com/nix-community/home-manager/issues/322#issuecomment-1856128020
    home.file.".ssh/config" = {
      target = ".ssh/config_source";
      onChange = ''cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config'';
    };
  };
}
