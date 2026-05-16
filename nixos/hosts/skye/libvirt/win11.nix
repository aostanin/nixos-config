{...}: {
  type = "kvm";
  name = "win11";
  uuid = "ea0ad3a5-20d4-47b0-8448-4946cbbae1d6";

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
    machine = "pc-q35-10.1";
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
      path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
    };
    boot = [{dev = "hd";}];
    smbios.mode = "host";
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
    };
    vmport.state = false;
    smm.state = true;
  };

  cpu = {
    mode = "host-passthrough";
    topology = {
      sockets = 1;
      cores = 4;
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
    suspend-to-mem.enabled = false;
    suspend-to-disk.enabled = false;
  };

  devices = {
    emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";

    disk = [
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
      {
        type = "file";
        device = "disk";
        driver = {
          name = "qemu";
          type = "raw";
        };
        source.file = "/var/lib/libvirt/images/rpool/win11/win11.img";
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
        ports = 15;
      }
      {
        type = "virtio-serial";
      }
    ];

    interface = {
      type = "network";
      mac.address = "52:54:00:04:0e:0b";
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
    ];

    input = [
      {
        type = "tablet";
        bus = "usb";
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
      listen.type = "none";
      gl.enable = true;
    };

    sound.model = "ich9";
    audio = {
      id = 1;
      type = "spice";
    };

    video.model = {
      type = "virtio";
      acceleration.accel3d = true;
    };

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
  };

  qemu-commandline.arg = [
    {value = "-acpitable";}
    {value = "file=/var/lib/libvirt/images/rpool/win11/msdm.bin";}
  ];
}
