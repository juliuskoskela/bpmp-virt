{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../bpmp-virt-common];

  boot.kernelPatches = [
    {
      name = "Bpmp Guest Proxy Dts";
      patch = ./patches/bpmp-guest-proxy-dts.patch;
    }
    {
      name = "BPMP virt enable guest";
      patch = null;
      extraStructuredConfig = with lib.kernel; {
        VFIO_PLATFORM = yes;
        TEGRA_BPMP_GUEST_PROXY = yes;
      };
    }
  ];
}
