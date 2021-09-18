{ sources ? import ./nix/sources.nix
, forge ? sources.forge
, pkgs ? import sources.nixpkgs {}
}:
with import ./. {};
{
  forge = minecraftForge {
    installer = forge;
    mods = map pkgs.fetchurl [
      {
        url = "https://edge.forgecdn.net/files/2555/164/jei_1.12.2-4.9.1.169.jar";
        hash = "sha256-yboKB0uZhLXYB6pZahnTjxNZIiNHABpwwtDe4On+Lto=";
      }
    ];
  };
  vanilla12 = minecraft {
    version = "1.12.2";
  };
  vanilla16 = minecraft {
    version = "1.16";
  };
}
