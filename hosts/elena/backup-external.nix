{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  drivePower = let
    baseUrl = secrets.backupExternal.homeAssistant.baseUrl;
    token = secrets.backupExternal.homeAssistant.token;
    entity = secrets.backupExternal.homeAssistant.entity;
  in
    pkgs.writeShellScript "drive_power" ''
      ${lib.getExe pkgs.curl} -S -s -o /dev/null -X POST \
          -H "Authorization: Bearer ${token}" \
          -d "{\"entity_id\": \"${entity}\"}" \
          "${baseUrl}/api/services/switch/turn_$1"
    '';
  # From https://gist.github.com/riyad/e7092f3d78db6af5ce1bc74af0c1bb50#file-zrepl-run-and-wait-for-job-sh
  zreplWait = pkgs.writeShellScript "zrepl_wait" ''
    zrepl_job_result=""  # result
    zrepl_error=""  # result
    zrepl_job="$1"

    echo "Running job ''${zrepl_job} ..."

    ${lib.getExe pkgs.zrepl} signal wakeup "''${zrepl_job}"
    delta_t=5  # seconds between loop iterations
    echo "NOTE: not all steps can be size-estimated, progress estimates may be imprecise."
    while :
    do
        sleep "''${delta_t}"

        # pluck the state of all the stages and unify them into a single array
        zrepl_job_result="$( \
          ${lib.getExe pkgs.zrepl} status --mode raw \
            | ZREPL_JOB="''${zrepl_job}" ${lib.getExe pkgs.jq} -c -r '
              .Jobs[$ENV.ZREPL_JOB].push | [.PruningReceiver.State?,.PruningSender.State?,.Replication.Attempts[-1].State] | map(tostring | ascii_downcase)
            ' \
        )"

        if [[ "''${zrepl_job_result}" = *err* ]]; then
            zrepl_error=1
            break
        fi

        # all done
        [[ $(${lib.getExe pkgs.jq} 'all(. == "done")' <<< "''${zrepl_job_result}") = "true" ]] && break
    done

    if [[ -z "''${zrepl_error}" ]]; then
        echo "Running job ''${zrepl_job} ... done"
    else
        echo "Error encountered while processing ''${zrepl_job} job."
        echo "Run the following command for details: zrepl status --job ''${zrepl_job}"
        echo "Running job ''${zrepl_job} ... failed"
    fi
  '';
in {
  systemd = {
    timers.backup-external = {
      wantedBy = ["timers.target"];
      partOf = ["backup-external.service"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      timerConfig = {
        OnCalendar = "*-*-* 18:15:00";
        Persistent = true;
      };
    };
    services.backup-external = {
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 30"; # Network is offline when resuming from sleep
      };
      script = let
        drives = secrets.backupExternal.drives;
        zfsUser = config.boot.zfs.package;
      in ''
        ${drivePower} on

        # Wait for drives to become available
        while ${lib.concatStringsSep " || " (map (drive: "[ ! -b ${drive} ]") drives)}; do
            sleep 1
        done

        ${lib.getExe' zfsUser "zpool"} import -f external

        ${zreplWait} external-push

        # Scrub once per month
        if [ `date +%d` == "01" ]; then
          ${lib.getExe' zfsUser "zpool"} scrub -w external
        fi

        ${lib.optionalString config.localModules.scrutinyCollector.enable ''
          # Collect external drive health stats for scrutiny
          systemctl start scrutiny-collector.service
        ''}

        ${lib.getExe' zfsUser "zpool"} status external
        ${lib.getExe' zfsUser "zpool"} export external

        # Spin down the backup drives before turning them off
        ${lib.getExe pkgs.hdparm} -Y ${lib.concatStringsSep " " drives}
        sleep 10

        ${drivePower} off
      '';
    };
  };
}
