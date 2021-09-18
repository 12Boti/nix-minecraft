{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs {}
}:
with import ./. {};
{
  forge = minecraftForge {
    version = "1.12.2-14.23.5.2855";
    hash = "sha256-x/vHOOXwdi6KbSJdmF2chaN2TI3dxq6a+4EpA63KX8k=";
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
