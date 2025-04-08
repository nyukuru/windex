{
  stdenvNoCC,
  requireFile,

  p7zip,
  guestfs-tools,
  wimlib,


  memmory ? "4G",

  virtioDrivers,
}: stdenvNoCC.mkDerivation {

  src = requireFile {
      name = "Win11_24H2_EnglishInternational_x64.iso";
      url = "https://www.microsoft.com/en-us/software-download/windows11/";
      # Find hash for other versions with 'nix-hash --type sha256 --sri --flat <file>'
      hash = "sha256-1aTJfD6DXEOxuaMZMzJ8ABdmzjFGCLqRLy//yHYEQwk=";
    };

  unpackCmd = "7z x -y $curSrc -oout";

  nativeBuildInputs = [
    guestfs-tools
    wimlib
    p7zip
  ];

  installPhase = ''
    # Allow image to fit in fat32 part
    wimsplit sources/install.wim 4090
    
  '';

}
