{
  inputs.forge = {
    url = "github:MinecraftForge/MinecraftForge";
    flake = false;
  };

  outputs = { self, nixpkgs, forge }: {
    defaultPackage.x86_64-linux =
      import ./. {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      };

    packages.x86_64-linux.forge = import ./forge.nix {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      src = forge;
    };
  };
}
