import ipaddress
import json
import re
import socket
import struct
import subprocess
import sys
import time

ALL_NODES = "ff02::1"


def icmp6_socket(ifname):
    idx = socket.if_nametoindex(ifname)
    s = socket.socket(socket.AF_INET6, socket.SOCK_RAW, socket.IPPROTO_ICMPV6)
    # Hosts discard neighbour discovery that didn't arrive with hop limit 255.
    s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_HOPS, 255)
    s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_IF, idx)
    return s, idx


def goodbye_ra(lan):
    # Router lifetime 0: clients drop this node as a default router now instead
    # of spreading flows over both routers until the old RA expires.
    s, idx = icmp6_socket(lan)
    ra = struct.pack("!BBHBBHII", 134, 0, 0, 64, 0, 0, 0, 0)
    for _ in range(3):
        s.sendto(ra, (ALL_NODES, 0, 0, idx))
        time.sleep(1)


def ip_json(*args):
    return json.loads(subprocess.run(["ip", "-j", *args], check=True, capture_output=True, text=True).stdout)


def wan_prefix(wan):
    for iface in ip_json("-6", "addr", "show", "dev", wan, "scope", "global", "-temporary"):
        # Filtered-out addresses still appear, as empty objects.
        for a in iface.get("addr_info", []):
            if "local" in a:
                return ipaddress.ip_network(f"{a['local']}/64", strict=False)
    return None


def lan_clients(lan, prefix, own):
    found = set()
    for n in ip_json("-6", "neigh", "show", "dev", lan):
        if "dst" in n and "FAILED" not in n.get("state", []):
            found.add(n["dst"])
    ct = subprocess.run(["conntrack", "-L", "-f", "ipv6"], capture_output=True, text=True).stdout
    for line in ct.splitlines():
        m = re.search(r"src=([0-9a-f:]+)", line)
        if m:
            found.add(m.group(1))
    return {a for a in found if ipaddress.ip_address(a) in prefix and a not in own}


def refresh_na(wan, lan, seconds):
    # The upstream router caches which MAC answered for each proxied LAN address,
    # so after a failover it keeps sending replies to the old master. Override
    # advertisements move those entries to this node's WAN MAC.
    s, idx = icmp6_socket(wan)
    with open(f"/sys/class/net/{wan}/address") as f:
        mac = bytes.fromhex(f.read().strip().replace(":", ""))
    sent = {}
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        prefix = wan_prefix(wan)
        if prefix:
            own = {
                a["local"]
                for dev in (wan, lan)
                for iface in ip_json("-6", "addr", "show", "dev", dev)
                for a in iface.get("addr_info", [])
                if "local" in a
            }
            for addr in lan_clients(lan, prefix, own):
                if sent.get(addr, 0) >= 3:
                    continue
                # R (router) + O (override), then a target link-layer address option.
                na = struct.pack("!BBHI", 136, 0, 0, 0xA0000000)
                na += socket.inet_pton(socket.AF_INET6, addr)
                na += struct.pack("!BB", 2, 1) + mac
                s.sendto(na, (ALL_NODES, 0, 0, idx))
                sent[addr] = sent.get(addr, 0) + 1
        time.sleep(2)
    print(f"advertised {len(sent)} LAN addresses on {wan}")


if __name__ == "__main__":
    if sys.argv[1] == "goodbye-ra":
        goodbye_ra(sys.argv[2])
    elif sys.argv[1] == "refresh-na":
        refresh_na(sys.argv[2], sys.argv[3], int(sys.argv[4]))
    else:
        sys.exit(f"unknown command {sys.argv[1]}")
