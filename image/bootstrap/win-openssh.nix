{
  stdenvNoCC,
  fetchurl
}: 
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "win-openssh";
  version = "9.8.3.0p2-Preview";

  # TODO:: not sure where they upload stable builds...
  src = fetchurl {
    url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v${finalAttrs.version}/OpenSSH-Win64.zip";
    hash = "sha256-DKEx86ePQE3IGaYzZgbK7A2xZjppLMw68ekCMnBq2lQ=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    cp $src $out
  '';
})
