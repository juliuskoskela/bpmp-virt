{
  config,
  lib,
  pkgs,
  system,
  microvm,
  ...
}: let
  bpmpDtb = ./uarta-qemu-8.1.0.dtb;
in {
  uartaVm = microvm.nixosModules.microvm {
    hypervisor = "qemu";
    machine = "virt,accel=kvm";
    cpu = "host";
    memorySize = "1G";
    rebootOnExit = false;
    networks = [
      {
        type = "user";
        hostForwarding = [
          {
            protocol = "tcp";
            hostPort = 2222;
            guestPort = 22;
          }
        ];
      }
      {
        type = "nic";
      }
    ];
    devices = [
      {
        type = "vfio-platform";
        options = "host=3100000.serial";
      }
    ];
    extraArgs = [
      "-dtb ${bpmpDtb}"
      "-append \"rootwait root=/dev/vda console=ttyAMA0\""
    ];
  };
}
