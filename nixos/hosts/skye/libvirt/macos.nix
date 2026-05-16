{lib, ...}: {
  type = "kvm";
  name = "macOS";
  uuid = "69020471-f271-4769-824f-adcb0fa9a675";

  memory = {
    count = 8;
    unit = "GiB";
  };
  vcpu = {
    placement = "static";
    count = 8;
  };
  iothreads.count = 1;

  cputune = {
    vcpupin =
      lib.genList (i: {
        vcpu = i;
        cpuset = toString (i + 2);
      })
      7;
    emulatorpin.cpuset = "0-1";
    iothreadpin = {
      iothread = 1;
      cpuset = "0-1";
    };
  };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-4.2";
    loader = {
      readonly = true;
      type = "pflash";
      path = "/var/lib/libvirt/images/rpool/macOS/OVMF_CODE.fd";
    };
    nvram = {
      format = "raw";
      path = "/var/lib/libvirt/images/rpool/macOS/OVMF_VARS-1920x1080.fd";
    };
  };

  features = {
    acpi = {};
    apic = {};
  };

  cpu = {
    mode = "custom";
    match = "exact";
    check = "none";
    model = {
      fallback = "forbid";
      name = "qemu64";
    };
    topology = {
      sockets = 1;
      cores = 4;
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

  devices = {
    emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";

    disk = [
      {
        type = "file";
        device = "disk";
        driver = {
          name = "qemu";
          type = "qcow2";
          cache = "writeback";
        };
        source.file = "/var/lib/libvirt/images/rpool/macOS/OpenCore/OpenCore.qcow2";
        target = {
          dev = "sda";
          bus = "sata";
        };
        boot = {order = 1;};
      }
      {
        type = "file";
        device = "disk";
        driver = {
          name = "qemu";
          type = "raw";
          cache = "writeback";
        };
        source.file = "/var/lib/libvirt/images/rpool/macOS/mac_hdd_ng.img";
        target = {
          dev = "vdb";
          bus = "virtio";
        };
      }
    ];

    controller = [
      {
        type = "usb";
        model = "ich9-ehci1";
      }
      {
        type = "usb";
        model = "ich9-uhci1";
        master.startport = 0;
      }
      {
        type = "usb";
        model = "ich9-uhci2";
        master.startport = 2;
      }
      {
        type = "usb";
        model = "ich9-uhci3";
        master.startport = 4;
      }
    ];

    interface = {
      type = "network";
      mac.address = "52:54:00:ab:5e:47";
      source.network = "default";
      model.type = "vmxnet3";
    };

    input = [
      {
        type = "keyboard";
        bus = "usb";
      }
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

    video.model.type = "virtio";

    hub.type = "usb";

    memballoon.model = "none";
  };

  qemu-commandline.arg = [
    {value = "-device";}
    {value = "isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc";}
    {value = "-smbios";}
    {value = "type=2";}
    {value = "-cpu";}
    {value = "Haswell-noTSX,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check";}
  ];
}
