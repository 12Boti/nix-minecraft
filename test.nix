{ sources ? import ./nix/sources.nix
, forge ? sources.forge
, pkgs ? import sources.nixpkgs {}
}:
with import ./. {};
{
  forge = minecraftForge {
    installer = forge;
    mods = map curseforgeMod [
      # JEI
      {
        projectId = 238222;
        fileId = 3043174;
        hash = "sha256-nbwsDsjCiCH91dykh5CQiVAWB+4lwOhHDEPJ/QvRIFM=";
      }
    ];
  };
  vanilla12 = minecraft {
    version = "1.12.2";
  };
  vanilla16 = minecraft {
    version = "1.16";
  };
  mod = curseforgeMod {
    projectId = 238222;
    fileId = 3448057;
    hash = "sha256-Q4j9n1sZ2ccjz9DLBznVjvmZlNwNHYeaG1Tr1Zh38go=";
  };
}
