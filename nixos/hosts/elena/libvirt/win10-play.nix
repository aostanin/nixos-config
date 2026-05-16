{lib, ...}: {
  type = "kvm";
  name = "win10-play";
  uuid = "8e78cd83-3a71-4559-a921-70ed369b4d2d";

  memory = {
    count = 32;
    unit = "GiB";
  };
  vcpu = {
    placement = "static";
    count = 14;
  };
  iothreads.count = 1;

  cputune = {
    vcpupin =
      lib.genList (i: {
        vcpu = i;
        cpuset = toString (i + 2);
      })
      14;
    emulatorpin.cpuset = "0-1";
    iothreadpin = {
      iothread = 1;
      cpuset = "0-1";
    };
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
      path = "/var/lib/libvirt/images/vmpool/win10-play/win10-play_VARS.fd";
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
      vpindex.state = true;
      runtime.state = true;
      synic.state = true;
      stimer = {
        state = true;
        direct.state = true;
      };
      reset.state = true;
      frequencies.state = true;
      reenlightenment.state = true;
      tlbflush.state = true;
      ipi.state = true;
      evmcs.state = false;
    };
    kvm.hidden.state = true;
    vmport.state = false;
    ioapic.driver = "kvm";
  };

  cpu = {
    mode = "host-passthrough";
    topology = {
      sockets = 1;
      cores = 7;
      threads = 2;
    };
    maxphysaddr = {
      mode = "passthrough";
      limit = 39;
    };
  };

  clock = {
    offset = "utc";
    timer = [
      {
        name = "pit";
        tickpolicy = "delay";
      }
      {
        name = "rtc";
        tickpolicy = "catchup";
        track = "guest";
      }
      {
        name = "hpet";
        present = false;
      }
      {
        name = "tsc";
        present = true;
        mode = "native";
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
          iothread = 1;
        };
        source.file = "/var/lib/libvirt/images/vmpool/win10-play/win10-play.img";
        target = {
          dev = "vda";
          bus = "virtio";
        };
      }
      {
        type = "file";
        device = "disk";
        driver = {
          name = "qemu";
          type = "raw";
          cache = "none";
          discard = "unmap";
        };
        source.file = "/var/lib/libvirt/images/vmpool/win10-play/win10-play-games-fast.img";
        target = {
          dev = "vdb";
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
          dev = "sdd";
          bus = "sata";
        };
        readonly = {};
      }
    ];

    controller = [
      {
        type = "usb";
        model = "piix3-uhci";
      }
      {
        type = "usb";
        model = "piix3-uhci";
      }
      {
        type = "usb";
        model = "piix3-uhci";
      }
      {
        type = "usb";
        model = "piix3-uhci";
      }
      {
        type = "virtio-serial";
      }
    ];

    interface = {
      type = "network";
      mac.address = "52:54:00:37:07:95";
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
        type = "mouse";
        bus = "virtio";
      }
      {
        type = "keyboard";
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
      port = 5910;
      autoport = false;
      listen = {
        type = "address";
        address = "127.0.0.1";
      };
    };

    sound = {
      model = "usb";
      audio.id = 1;
    };
    audio = {
      id = 1;
      type = "spice";
    };

    video.model.type = "none";

    hostdev = [
      {
        mode = "subsystem";
        type = "pci";
        managed = true;
        source.address = {
          domain = 0;
          bus = 1;
          slot = 0;
          function = 0;
        };
      }
      {
        mode = "subsystem";
        type = "pci";
        managed = true;
        source.address = {
          domain = 0;
          bus = 1;
          slot = 0;
          function = 1;
        };
      }
      {
        mode = "subsystem";
        type = "pci";
        managed = true;
        source.address = {
          domain = 0;
          bus = 1;
          slot = 0;
          function = 2;
        };
      }
      {
        mode = "subsystem";
        type = "pci";
        managed = true;
        source.address = {
          domain = 0;
          bus = 1;
          slot = 0;
          function = 3;
        };
      }
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

    memballoon.model = "none";
  };

  qemu-commandline.arg = [
    {value = "-smbios";}
    {value = "type=4,manufacturer=Intel(R) Corporation,version=13th Gen Intel(R) Core(TM) i7-13700K";}
    {value = "-smbios";}
    {value = "type=17,manufacturer=Corsair";}
    {value = "-device";}
    {value = ''{"driver":"ivshmem-plain","id":"shmem0","memdev":"looking-glass"}'';}
    {value = "-object";}
    {value = ''{"qom-type":"memory-backend-file","id":"looking-glass","mem-path":"/dev/kvmfr0","size":67108864,"share":true}'';}
  ];
}
