{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  python3Packages,
  zlib,
  pkg-config,
  glib,
  buildPackages,
  pixman,
  vde2,
  alsa-lib,
  texinfo,
  flex,
  bison,
  lzo,
  snappy,
  libaio,
  libtasn1,
  gnutls,
  nettle,
  curl,
  ninja,
  meson,
  # sigtool,
  makeWrapper,
  removeReferencesTo,
  attr,
  libcap,
  libcap_ng,
  socat,
  libslirp,
  # CoreServices,
  # Cocoa,
  # Hypervisor,
  # rez,
  # setfile,
  # vmnet,
}: let
  version = "8.1.0";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "qemu-bpmp";
  version = version;

  srcs = [
    (fetchurl {
      url = "https://download.qemu.org/qemu-${version}.tar.xz";
      sha256 = "0m8fbyr3xv6gi95ma0sksxfqmyj3pi4zcrgg5rvd8d73k08i033i";
    })
  ];

  sourceRoot = "qemu-${version}";

  nativeBuildInputs = [
    makeWrapper
    removeReferencesTo
    pkg-config
    flex
    bison
    meson
    ninja

    # Don't change this to python3 and python3.pkgs.*, breaks cross-compilation
    python3Packages.python
    python3Packages.sphinx
    python3Packages.sphinx-rtd-theme
  ];

  buildInputs = [
    zlib
    glib
    pixman
    vde2
    texinfo
    lzo
    snappy
    libtasn1
    gnutls
    nettle
    curl
    libslirp
  ];

  enableParallelBuilding = true;

  # patches = [
  #   ./qemu-bpmp-virt-8.1.0.patch
  # ];

  postPatch = ''
    # Otherwise tries to ensure /var/run exists.
    sed -i "/install_emptydir(get_option('localstatedir') \/ 'run')/d" \
        qga/meson.build
  '';

  preConfigure = ''
    unset CPP # intereferes with dependency calculation
    # this script isn't marked as executable b/c it's indirectly used by meson. Needed to patch its shebang
    chmod +x ./scripts/shaderinclude.py
    patchShebangs .
    # avoid conflicts with libc++ include for <version>
    mv VERSION QEMU_VERSION
    substituteInPlace configure \
      --replace '$source_path/VERSION' '$source_path/QEMU_VERSION'
    substituteInPlace meson.build \
      --replace "'VERSION'" "'QEMU_VERSION'"
  '';

  configureFlags = [
    "--disable-strip" # We'll strip ourselves after separating debug info.
    # (lib.enableFeature enableDocs "docs")
    "--enable-tools"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--cross-prefix=${stdenv.cc.targetPrefix}"
    # (lib.enableFeature guestAgentSupport "guest-agent")
  ];

  dontWrapGApps = true;

  postFixup =
    ''
      # the .desktop is both invalid and pointless
      rm -f $out/share/applications/qemu.desktop
    ''
    # + lib.optionalString guestAgentSupport ''
    #   # move qemu-ga (guest agent) to separate output
    #   mkdir -p $ga/bin
    #   mv $out/bin/qemu-ga $ga/bin/
    #   ln -s $ga/bin/qemu-ga $out/bin
    #   remove-references-to -t $out $ga/bin/qemu-ga
    # ''
    # + lib.optionalString gtkSupport ''
    #   # wrap GTK Binaries
    #   for f in $out/bin/qemu-system-*; do
    #     wrapGApp $f
    #   done
    # ''
    ;

  preBuild = "cd build";

  doCheck = false;

  nativeCheckInputs = [socat];

  preCheck =
    ''
      # time limits are a little meagre for a build machine that's
      # potentially under load.
      substituteInPlace ../tests/unit/meson.build \
        --replace 'timeout: slow_tests' 'timeout: 50 * slow_tests'
      substituteInPlace ../tests/qtest/meson.build \
        --replace 'timeout: slow_qtests' 'timeout: 50 * slow_qtests'
      substituteInPlace ../tests/fp/meson.build \
        --replace 'timeout: 90)' 'timeout: 300)'

      # point tests towards correct binaries
      substituteInPlace ../tests/unit/test-qga.c \
        --replace '/bin/bash' "$(type -P bash)" \
        --replace '/bin/echo' "$(type -P echo)"
      substituteInPlace ../tests/unit/test-io-channel-command.c \
        --replace '/bin/socat' "$(type -P socat)"

      # combined with a long package name, some temp socket paths
      # can end up exceeding max socket name len
      substituteInPlace ../tests/qtest/bios-tables-test.c \
        --replace 'qemu-test_acpi_%s_tcg_%s' '%s_%s'

      # get-fsinfo attempts to access block devices, disallowed by sandbox
      sed -i -e '/\/qga\/get-fsinfo/d' -e '/\/qga\/blacklist/d' \
        ../tests/unit/test-qga.c
    ''
    + lib.optionalString stdenv.isDarwin ''
      # skip test that stalls on darwin, perhaps due to subtle differences
      # in fifo behaviour
      substituteInPlace ../tests/unit/meson.build \
        --replace "'test-io-channel-command'" "#'test-io-channel-command'"
    '';

  # Add a ‘qemu-kvm’ wrapper for compatibility/convenience.
  postInstall = ''
    ln -s $out/bin/qemu-system-${stdenv.hostPlatform.qemuArch} $out/bin/qemu-kvm
  '';

  passthru = {
    qemu-system-i386 = "bin/qemu-system-i386";
    tests = {
      qemu-tests = finalAttrs.finalPackage.overrideAttrs (_: {doCheck = true;});
    };
    # updateScript = gitUpdater {
    #   # No nicer place to find latest release.
    #   url = "https://gitlab.com/qemu-project/qemu.git";
    #   rev-prefix = "v";
    #   ignoredVersions = "(alpha|beta|rc).*";
    # };
  };

  meta = with lib; {
    homepage = "http://www.qemu.org/";
    description = "Fork of QEMU with AFL instrumentation support";
    license = licenses.gpl2Plus;
    # maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
})
