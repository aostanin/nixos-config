{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  uplink = config.localModules.home-server.interface;
in {
  # br0 for the dev container and the VMs.
  localModules.home-server = {
    enable = true;
    interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE0}";
    # The router's reservation for valmar is keyed on the onboard NIC's MAC,
    # which br0 keeps.
    inherit (secrets.network.home.hosts.valmar) address macAddress;
  };

  # Sunshine sends each frame as a 10G line-rate burst, which the switch
  # tail-drops on its 1G ports. Pace only the video stream (UDP source port
  # 47998) below 1G; cake also splits Linux UDP GSO batches, which HTB passes
  # through whole.
  # https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2troubleshooting.html
  # ("Packet loss (Buffer overrun)")
  systemd.services.sunshine-uplink-pacing = {
    after = ["sys-subsystem-net-devices-${uplink}.device"];
    bindsTo = ["sys-subsystem-net-devices-${uplink}.device"];
    wantedBy = ["sys-subsystem-net-devices-${uplink}.device" "multi-user.target"];
    path = [pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      tc qdisc del dev ${uplink} root || true
      tc qdisc add dev ${uplink} root handle 1: prio bands 2 priomap 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
      tc qdisc add dev ${uplink} parent 1:1 handle 10: cake bandwidth 900mbit besteffort
      tc qdisc add dev ${uplink} parent 1:2 handle 20: fq_codel
      tc filter add dev ${uplink} parent 1: protocol ip prio 1 flower ip_proto udp src_port 47998 classid 1:1
      tc filter add dev ${uplink} parent 1: protocol ipv6 prio 2 flower ip_proto udp src_port 47998 classid 1:1
    '';
    preStop = ''
      tc qdisc del dev ${uplink} root || true
    '';
  };
}
