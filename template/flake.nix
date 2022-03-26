{
  inputs.nix-minecraft.url = "github:12Boti/nix-minecraft";

  outputs =
    { self
    , nixpkgs
    , nix-minecraft
    }:
    {
      defaultPackage.x86_64-linux = nix-minecraft.lib.x86_64-linux.mkMinecraft {
        username = "NixDude";
        gamedir = "./gamedir";
        minecraft.version = "1.18";
      };
    };
}
