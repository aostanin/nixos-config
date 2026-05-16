{...}: {
  type = "kvm";
  name = "win10-work";
  uuid = "08ae37df-467c-45c4-8f31-53add09a5aea";

  memory = {
    count = 16;
    unit = "GiB";
  };
  memoryBacking = {
    source.type = "memfd";
    access.mode = "shared";
  };
  vcpu = {
    placement = "static";
    count = 4;
  };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-10.1";
    loader = {
      readonly = true;
      type = "pflash";
      path = "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd";
    };
    nvram = {
      template = "/run/libvirt/nix-ovmf/edk2-i386-vars.fd";
      format = "raw";
      path = "/var/lib/libvirt/qemu/nvram/win10-work_VARS.fd";
    };
    boot = [{dev = "hd";}];
    smbios = {mode = "host";};
  };

  features = {
    acpi = {};
    apic = {};
    hyperv = {
      mode = "custom";
      relaxed.state = true;
      vapic.state = true;
      spinlocks = {
        state = true;
        retries = 8191;
      };
      vendor_id = {
        state = true;
        value = "whatever";
      };
    };
    vmport.state = false;
  };

  cpu = {
    mode = "host-passthrough";
    topology = {
      sockets = 1;
      cores = 2;
      threads = 2;
    };
  };

  clock = {
    offset = "localtime";
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
      {
        name = "hypervclock";
        present = true;
      }
    ];
  };

  pm = {
    suspend-to-mem.enabled = true;
    suspend-to-disk.enabled = true;
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
          cache = "none";
          discard = "unmap";
        };
        source.file = "/var/lib/libvirt/images/vmpool/win10-work/win10-work.img";
        target = {
          dev = "sda";
          bus = "sata";
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
          dev = "sdb";
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
      mac.address = "52:54:00:57:ce:b1";
      source.network = "default";
      model.type = "virtio";
    };

    serial.type = "pty";
    console.type = "pty";

    channel = [
      {
        type = "spicevmc";
        target = {
          type = "virtio";
          name = "com.redhat.spice.0";
        };
      }
      {
        type = "unix";
        target = {
          type = "virtio";
          name = "org.qemu.guest_agent.0";
        };
      }
    ];

    input = [
      {
        type = "keyboard";
        bus = "virtio";
      }
      {
        type = "tablet";
        bus = "virtio";
      }
    ];

    tpm = {
      model = "tpm-crb";
      backend = {
        type = "emulator";
        version = "2.0";
      };
    };

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

    hostdev = [
      {
        mode = "subsystem";
        type = "pci";
        managed = true;
        source.address = {
          domain = 0;
          bus = 6;
          slot = 0;
          function = 0;
        };
      }
    ];

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

    memballoon.model = "none";
  };
}
