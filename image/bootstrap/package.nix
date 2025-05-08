{
  lib,
  runCommandNoCC,
  qemu_kvm,
  guestfs-tools,

  win-virtio,
  win-openssh,
  bundle-installer,
}: 
runCommandNoCC "bootstrap.img" {
    buildInputs = [
      qemu_kvm
      guestfs-tools
    ];
  } 
  ''
    if ! test -f; then
      echo "KVM not available, bailing out" >> /dev/stderr
      exit 1
    fi

    cp -r ${win-virtio} ./virtio

    cp ${lib.getExe bundle-installer} ./win-bundle-installer.nix
    cp ${win-openssh} ./OpenSSH-Win64.zip

    cp ${./setup.ps1} ./setup.ps1

    virt-make-fs --partition --type=fat ./ $out
  ''
