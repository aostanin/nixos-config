{
  lib,
  pkgs,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "unifi";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {
      port = 8443;
      scheme = "https";
    };
    volumes = mkVolumesOption name {
      config = {
        user = uid;
        group = gid;
      };
      db = {};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
    };

    sops.secrets = {
      "containers/unifi/mongo_pass" = {};
      "containers/unifi/mongo_initdb_root_password" = {};
    };

    sops.templates."${name}.env".content = ''
      MONGO_PASS=${config.sops.placeholder."containers/unifi/mongo_pass"}
    '';

    sops.templates."${name}-db.env".content = ''
      MONGO_INITDB_ROOT_PASSWORD=${config.sops.placeholder."containers/unifi/mongo_initdb_root_password"}
      MONGO_PASS=${config.sops.placeholder."containers/unifi/mongo_pass"}
    '';

    localModules.containers.networks.${name} = {};

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/linuxserver/unifi-network-application:latest";
        dependsOn = ["${name}-db"];
        ports = [
          "3478:3478/udp" # STUN
          "10001:10001/udp" # Device discovery
          "8080:8080" # Device and controller communication
          "8443:8443" # Controller GUI/API
          # "1900:1900/udp" # Make controller discoverable on L2 network
          # "8843:8843" # HTTPS portal redirection
          # "8880:8880" # HTTP portal redirection
          # "6789:6789" # UniFi mobile speed test
          # "5514:5514/udp" # Remote syslog capture
        ];
        environment = {
          PUID = uid;
          PGID = gid;
          MONGO_USER = "unifi";
          MONGO_HOST = "${name}-db";
          MONGO_PORT = "27017";
          MONGO_DBNAME = "unifi";
          MONGO_AUTHSOURCE = "admin";
        };
        environmentFiles = [config.sops.templates."${name}.env".path];
        volumes = [
          "${cfg.volumes.config.path}:/config"
        ];
        extraOptions = ["--network=${name}"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    virtualisation.oci-containers.containers."${name}-db" = lib.mkMerge [
      {
        image = "docker.io/library/mongo:7";
        environment = {
          MONGO_INITDB_ROOT_USERNAME = "root";
          MONGO_USER = "unifi";
          MONGO_DBNAME = "unifi";
          MONGO_AUTHSOURCE = "admin";
        };
        environmentFiles = [config.sops.templates."${name}-db.env".path];
        volumes = let
          init = pkgs.writeTextFile {
            name = "init-mongo.sh";
            text = ''
              #!/bin/bash

              if which mongosh > /dev/null 2>&1; then
                mongo_init_bin='mongosh'
              else
                mongo_init_bin='mongo'
              fi
              "''${mongo_init_bin}" <<EOF
              use ''${MONGO_AUTHSOURCE}
              db.auth("''${MONGO_INITDB_ROOT_USERNAME}", "''${MONGO_INITDB_ROOT_PASSWORD}")
              db.createUser({
                user: "''${MONGO_USER}",
                pwd: "''${MONGO_PASS}",
                roles: [
                  { db: "''${MONGO_DBNAME}", role: "dbOwner" },
                  { db: "''${MONGO_DBNAME}_stat", role: "dbOwner" }
                ]
              })
              EOF
            '';
            executable = true;
          };
        in [
          "${cfg.volumes.db.path}:/data/db"
          "${init}:/docker-entrypoint-initdb.d/init-mongo.sh:ro"
        ];
        extraOptions = ["--network=${name}"];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = lib.mkMerge [
      (mkServiceProxyConfig name cfg.proxy)
      (mkServiceNetworksConfig name [name])
    ];
    systemd.services."podman-${name}-db" = mkServiceNetworksConfig name [name];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
