{
  lib,
  pkgs,
  config,
  ...
}: let
  name = "unifi";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };
  };

  config = lib.mkIf cfg.enable {
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

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/linuxserver/unifi-network-application:latest";
      networks = [name];
      raw.dependsOn = ["${name}-db"];
      raw.ports = [
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
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        MONGO_USER = "unifi";
        MONGO_HOST = "${name}-db";
        MONGO_PORT = "27017";
        MONGO_DBNAME = "unifi";
        MONGO_AUTHSOURCE = "admin";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.config = {
        destination = "/config";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      proxy = {
        enable = true;
        port = 8443;
        scheme = "https";
      };
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/library/mongo:7";
      networks = [name];
      raw.environment = {
        MONGO_INITDB_ROOT_USERNAME = "root";
        MONGO_USER = "unifi";
        MONGO_DBNAME = "unifi";
        MONGO_AUTHSOURCE = "admin";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/data/db";
      };
      raw.volumes = let
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
      in ["${init}:/docker-entrypoint-initdb.d/init-mongo.sh:ro"];
    };
  };
}
