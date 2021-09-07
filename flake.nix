{
  outputs = { self, nixpkgs, forge }: {
    defaultPackage.x86_64-linux =
      import ./. {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      };
  };
}
