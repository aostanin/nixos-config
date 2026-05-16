{lib, ...}: {
  type = "kvm";
  name = "OpenWRT";
  uuid = "24746d7e-4cb2-40a0-ba34-240404fdfc69";

  memory = {
    count = 256;
    unit = "MiB";
  };
  vcpu = {
    placement = "static";
    count = 2;
  };

  cputune = {
    vcpupin =
      lib.genList (i: {
        vcpu = i;
        cpuset = toString (i + 2);
      })
      2;
    emulatorpin.cpuset = "0-1";
  };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-8.0";
    loader = {
      readonly = true;
      type = "pflash";
      path = "/run/libvirt/nix-ovmf/edk2-x86_64-code.fd";
    };
    nvram = {
      template = "/run/libvirt/nix-ovmf/edk2-i386-vars.fd";
      templateFormat = "raw";
      format = "raw";
      path = "/var/lib/libvirt/images/OpenWRT/OpenWRT_VARS.fd";
    };
    boot = [{dev = "hd";}];
  };

  features = {
    acpi = {};
    apic = {};
    vmport.state = false;
  };

  cpu = {
    mode = "host-passthrough";
    topology = {
      sockets = 1;
      cores = 1;
      threads = 2;
    };
  };

  clock = {
    offset = "utc";
    timer = [
      {
        name = "rtc";
        tickpolicy = "catchup";
      }
      {
        name = "pit";
        tickpolicy = "delay";
      }
      {
        name = "hpet";
        present = false;
      }
    ];
  };

  on_crash = "restart";
  pm = {
    suspend-to-mem.enabled = false;
    suspend-to-disk.enabled = false;
  };

  devices = {
    emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";

    disk = [
      {
        type = "file";
        device = "disk";
        driver = {
          name = "qemu";
          type = "raw";
        };
        source.file = "/var/lib/libvirt/images/OpenWRT/openwrt.img";
        target = {
          dev = "vda";
          bus = "virtio";
        };
      }
    ];

    controller = [
      {
        type = "usb";
        model = "qemu-xhci";
      }
      {
        type = "virtio-serial";
      }
    ];

    interface = {
      type = "network";
      mac.address = "52:54:00:34:64:f1";
      source.network = "default";
      model.type = "virtio";
    };

    serial.type = "pty";
    console.type = "pty";

    channel = [
      {
        type = "unix";
        target = {
          type = "virtio";
          name = "org.qemu.guest_agent.0";
        };
      }
    ];

    graphics = {
      type = "spice";
      autoport = true;
      listen.type = "address";
    };
    audio = {
      id = 1;
      type = "spice";
    };
    video.model.type = "virtio";

    rng = {
      model = "virtio";
      backend = {
        model = "random";
        source = /dev/urandom;
      };
    };
  };
}
