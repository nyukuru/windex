{
  mkShell,
  qemu,
  p7zip,
}: mkShell {
  packages = [
    qemu
    p7zip
  ];
}
