{
  stdenvNoCC,
  requireFile,
  lib,

  p7zip,
  guestfs-tools,
  wimlib,
  swtpm,
  qemu_kvm,
  OVMFFull,

  bootstrap-image,
  autounattended,

  cores ? "4",
  memory ? "4G",
  diskImageSize ? "70G",
}: stdenvNoCC.mkDerivation {
  name = "windex.img";

  src = requireFile {
      name = "Win11_24H2_EnglishInternational_x64.iso";
      url = "https://www.microsoft.com/en-us/software-download/windows11/";
      # Find hash for other versions with 'nix-hash --type sha256 --sri --flat <file>'
      hash = "sha256-1aTJfD6DXEOxuaMZMzJ8ABdmzjFGCLqRLy//yHYEQwk=";
    };

  unpackCmd = "7z x -y $curSrc -oOut/win";

  buildInputs = [
    guestfs-tools
    wimlib
    p7zip
    swtpm
    (qemu_kvm.override {tpmSupport = true;})
  ];

  buildPhase = let
    qemuParams = [
      "-enable-kvm"
      "-cpu host"
      "-smp ${cores}"
      "-m ${memory}"

      # Network
      "-netdev user,id=n1,net=192.168.1.0/24,restrict=on"

      # TPM
      "-chardev socket,id=chrtpm,path=tpmstate/tpm.sock"
      "-tpmdev emulator,id=tpm0,chardev=chrtpm"
      "-device tpm-tis,tpmdev=tpm0"

      # EFI
      "-machine q35,smm=on,accel=kvm"
      "-global driver=cfi.pflash01,property=secure,value=on"
      "-drive if=pflash,format=raw,unit=0,file=${OVMFFull.firmware},readonly=on"
      "-drive if=pflash,format=raw,unit=1,file=COPY-OF-OVMF_VARS.fd"

      # BOOTSTRAP IMAGE 
      "-drive id=bootstrap,file=${bootstrap-image},if=none,format=raw,readonly=on"
      "-device nec-usb-xhci,id=xhci"
      "-device usb-storage,bus=xhci.0,drive=bootstrap"

      # WIN IMAGE
      "-drive id=win-install,file=usbimage.img,if=none,format=raw,readonly=on,media=disk"
      "-device usb-storage,drive=win-install"

      # OUT IMAGE
      "-drive file=out.img,index=0,media=disk,if=virtio,cache=unsafe"
    ];

  in ''
    # Allow image to fit in fat32 part
    wimsplit win/sources/install.wim win/sources/install.swm 4090
    rm win/sources/install.wim

    echo "Creating Autounattended.xml"
    cp ${autounattended} win/autounattend.xml

    # Rebuild into an image
    echo "Building initial windows image"
    virt-make-fs --partition --type=fat win usbimage.img
    rm -rf win

    # Copy OVMF files
    echo "Copying OVMF"
    install -m 0777 ${OVMFFull.variables} COPY-OF-OVMF_VARS.fd

    echo "Creating Image"
    qemu-img create -f qcow2 out.img ${diskImageSize}

    # Start TPM
    echo "Starting TPM"
    mkdir -p tpmstate
    swtpm socket --tpmstate dir=tpmstate \
      --ctrl type=unixio,path=tpmstate/tpm.sock \
      --tpm2 &

    echo "Building Image"
    qemu-system-x86_64 ${lib.concatStringsSep " " qemuParams}
  '';

  installPhase = ''
    mv out.img $out
  '';

}
