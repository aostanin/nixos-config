{...}: {
  type = "kvm";
  name = "ubuntu";
  uuid = "56d62d43-7727-4696-adfb-e5f455b466ec";

  memory = {
    count = 8;
    unit = "GiB";
  };
  vcpu = {
    placement = "static";
    count = 8;
  };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-8.2";
    loader = {
      readonly = true;
      secure = true;
      type = "pflash";
      path = "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd";
    };
    nvram = {
      template = "/run/libvirt/nix-ovmf/edk2-i386-vars.fd";
      templateFormat = "raw";
      format = "raw";
      path = "/var/lib/libvirt/qemu/nvram/ubuntu_VARS.fd";
    };
    boot = [{dev = "hd";}];
  };

  features = {
    acpi = {};
    apic = {};
    vmport.state = false;
    smm.state = true;
  };

  cpu.mode = "host-passthrough";

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
        source.file = "/var/lib/libvirt/images/rpool/ubuntu/ubuntu.img";
        target = {
          dev = "vda";
          bus = "virtio";
        };
      }
      {
        type = "file";
        device = "cdrom";
        driver = {
          name = "qemu";
          type = "raw";
        };
        target = {
          dev = "sda";
          bus = "sata";
        };
        readonly = {};
      }
    ];

    controller = [
      {
        type = "usb";
        model = "qemu-xhci";
        ports = 15;
      }
      {
        type = "virtio-serial";
      }
    ];

    interface = {
      type = "network";
      mac.address = "52:54:00:4f:0f:54";
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
      {
        type = "spicevmc";
        target = {
          type = "virtio";
          name = "com.redhat.spice.0";
        };
      }
    ];

    input = [
      {
        type = "tablet";
        bus = "usb";
      }
    ];

    graphics = {
      type = "spice";
      autoport = true;
      listen.type = "address";
    };

    sound.model = "ich9";
    audio = {
      id = 1;
      type = "spice";
    };

    video.model.type = "qxl";

    redirdev = [
      {
        bus = "usb";
        type = "spicevmc";
      }
      {
        bus = "usb";
        type = "spicevmc";
      }
    ];

    rng = {
      model = "virtio";
      backend = {
        model = "random";
        source = /dev/urandom;
      };
    };
  };
}
