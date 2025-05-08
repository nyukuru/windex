{
  stdenvNoCC,
  fetchurl,

  p7zip,
}: 
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "win-virtio";
  version = "0.1.271-1";

  src = fetchurl {
    url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-${finalAttrs.version}/virtio-win.iso";
    hash = "sha256-u+YWathqSQyu+tQ4/viqSUkmywobN/oSEpJc/YFlZCk=";
  };

  unpackCmd = "7z x -y $curSrc -oOut";

  nativeBuildInputs = [
    p7zip
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r * $out
  '';
})
