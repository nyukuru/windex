{
  buildGoModule,
}: buildGoModule {
  pname = "bundle-installer";
  version = "1.0.0";

  src = ./.;
  
  vendorHash = null;

  meta = {
    mainProgram = "bundle";
  };
}
