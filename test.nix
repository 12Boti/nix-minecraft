{ sources ? import ./nix/sources.nix
, forge ? sources.forge
}:
with import ./. {};
{
  forge = minecraftForge {
    installer = forge;
  };
  vanilla12 = minecraft {
    version = "1.12.2";
  };
  vanilla16 = minecraft {
    version = "1.16";
  };
}
