(final: prev: {
  qemu_kvm = prev.qemu_kvm.overrideAttrs (_final: prev: {
    patches = prev.patches ++ [./patches/qemu-v8.1.0_bpmp-virt.patch];
  });
})
