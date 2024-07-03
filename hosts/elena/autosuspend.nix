{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  sops.secrets = {
    "jellyfin/token" = {};
    "navidrome/password" = {};
    "qbittorrent/password" = {};
    "tdarr/password" = {};
  };

  services.autosuspend = {
    enable = true;
    settings = {
      interval = 30;
      idle_time = 1800;
      # The default can't find echo
      wakeup_cmd = let
        echo = lib.getExe' pkgs.coreutils "echo";
      in "${lib.getExe pkgs.bash} -c '${echo} 0 > /sys/class/rtc/rtc0/wakealarm && ${echo} {timestamp:.0f} > /sys/class/rtc/rtc0/wakealarm'";
    };
    checks = {
      ActiveConnection.ports = lib.concatStringsSep "," [
        "22" # ssh
        "8888" # zrepl
        "8889" # zrepl
      ];
      LogindSessionsIdle = {};
      Processes.processes = lib.concatStringsSep "," [
        "mosh-server"
        "rsync"
      ];
      navidrome = {
        class = "ExternalCommand";
        command = let
          inherit (secrets.navidrome) baseUrl username;
          passwordFile = config.sops.secrets."navidrome/password".path;
        in
          toString (pkgs.writeShellScript "check_navidrome_playing" ''
            response=$(${lib.getExe pkgs.curl} -s "${baseUrl}/rest/getNowPlaying.view?u=${username}&p=$(cat ${passwordFile})&v=1.15.&c=curl")
            echo $response | ${lib.getExe' pkgs.yq "xq"} -e '."subsonic-response".nowPlaying != null'
          '');
      };
      jellyfin = {
        class = "ExternalCommand";
        command = let
          baseUrl = secrets.jellyfin.baseUrl;
          tokenFile = config.sops.secrets."jellyfin/token".path;
        in
          toString (pkgs.writeShellScript "check_jellyfin_sessions" ''
            sessions=$(${lib.getExe pkgs.curl} -s ${baseUrl}/sessions?api_key=$(cat ${tokenFile}))
            echo $sessions | ${lib.getExe pkgs.jq} -e '. | map(select(.NowPlayingItem != null)) != []'
          '');
      };
      qbittorrent = {
        class = "ExternalCommand";
        command = let
          inherit (secrets.qbittorrent) baseUrl username;
          passwordFile = config.sops.secrets."qbittorrent/password".path;
        in
          toString (pkgs.writeShellScript "check_qbittorrent_downloads" ''
            SID=$(${lib.getExe pkgs.curl} -s -o /dev/null -c - --data "username=${username}&password=$(cat ${passwordFile})" "${baseUrl}/api/v2/auth/login" | ${lib.getExe pkgs.gawk} 'END{print $NF}')
            torrents=$(${lib.getExe pkgs.curl} -s --cookie "SID=$SID" --data "filter=downloading&sort=dlspeed&reverse=true&limit=1" "${baseUrl}/api/v2/torrents/info")
            echo $torrents | ${lib.getExe pkgs.jq} -e '.[].dlspeed > 1000'
          '');
      };
      tdarr = {
        class = "ExternalCommand";
        command = let
          inherit (secrets.tdarr) baseUrl username;
          passwordFile = config.sops.secrets."tdarr/password".path;
        in
          toString (pkgs.writeShellScript "check_tdarr" ''
            nodes=$(${lib.getExe pkgs.curl} -s -u "${username}:$(cat ${passwordFile})" ${baseUrl}/api/v2/get-nodes)
            echo $nodes | ${lib.getExe pkgs.jq} -e '.[].workers | to_entries | map(select(.value.idle == false)) != []'
          '');
      };
      vms = {
        class = "ExternalCommand";
        command = toString (pkgs.writeShellScript "check_running_vms" ''
          status=$(${lib.getExe' pkgs.libvirt "virsh"} -q list --state-running | grep "running")
          if [ -z "$status" ]; then
            exit 1
          else
            exit 0
          fi
        '');
      };
      zfs = {
        class = "ExternalCommand";
        command = let
          zfsUser = config.boot.zfs.package;
        in
          toString (pkgs.writeShellScript "check_zfs" ''
            status=$(${lib.getExe' zfsUser "zpool"} status | grep "scrub in progress")
            if [ -z "$status" ]; then
              exit 1
            else
              exit 0
            fi
          '');
      };
    };
    wakeups = {
      backup_external = {
        class = "SystemdTimer";
        match = "zrepl-local-push.timer";
      };
    };
  };
}
