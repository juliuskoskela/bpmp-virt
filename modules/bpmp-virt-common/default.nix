{config, ...}: {
  nixpkgs.overlays = [import ../../overlays/qemu];

  boot.kernelPatches = [
    {
      name = "Added Configurations to Support Vda";
      patch = ./patches/added-configurations-to-support-vda.patch;
    }
    {
      name = "Vfio_platform Reset Required False";
      patch = ./pacthes/vfio_platform-reset-required-false.patch;
    }
    {
      name = "Bpmp Support Virtualization";
      patch = ./pacthes/bpmp-support-bpmp-virt.patch;
    }
    {
      name = "Bpmp Virt Drivers";
      patch = ./patches/bpmp-virt-drivers.patch;
    }
  ];

  boot.kernelParams = ["vfio_iommu_type1.allow_unsafe_interrupts=1"];
}
