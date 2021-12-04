{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
with import ./. { };
{
  forge10 = minecraftForge {
    version = "1.10.2-12.18.3.2511";
    mcSha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    hash = "sha256-DFB1b0lcYSOJQ2uRN0gVoNkWxNFf4Bb077PbRNnlFkI=";
  };
  forge12 = minecraftForge {
    version = "1.12.2-14.23.5.2855";
    mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    hash = "sha256-GPNLYZA+4fIZunpXTbp5zGqg6ZHK/QqTWyLmzPIRuYs=";
    mods = map curseforgeMod [
      # JEI
      {
        projectId = 238222;
        fileId = 3043174;
        hash = "sha256-nbwsDsjCiCH91dykh5CQiVAWB+4lwOhHDEPJ/QvRIFM=";
      }
    ];
  };
  liteloader10 = minecraftLiteloader {
    url = "http://dl.liteloader.com/redist/1.10.2/liteloader-installer-1.10.2-00.jar";
    mcSha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    hash = "sha256-OB5C71sl52XMIOtmuySYIoF31NLZEP/yfSPg0aQqtgU=";
    mods = map curseforgeMod [
      # Armors HUD Revived
      {
        projectId = 244537;
        fileId = 2317559;
        hash = "sha256-Q+s8EqmBizXpgGnel2PXWGLRPmVidWvMqQVmctbEK4o=";
      }
    ];
  };
  liteloader12 = minecraftLiteloader {
    url = "http://jenkins.liteloader.com/job/LiteLoaderInstaller%201.12.2/lastSuccessfulBuild/artifact/build/libs/liteloader-installer-1.12.2-00-SNAPSHOT.jar";
    mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    hash = "sha256-ehZd0+ELNegsq8NdkX7pJYg03MXmi1XriVxuqze0Cps=";
    mods = map pkgs.fetchurl [
      # Extended Hotbar
      {
        url = "https://github.com/DenWav/ExtendedHotbar/releases/download/1.2.0/mod-extendedhotbar-1.2.0-mc1.12.2.litemod";
        hash = "sha256-CyB7jypxXq41wAfb/t1RCsxaS8uZZjAl/h531osq0Fc=";
      }
    ];
  };
  fabric16 = minecraftFabric {
    mcVersion = "1.16.5";
    fabricVersion = "0.12.5";
    mcSha1 = "66935fe3a8f602111a3f3cba9867d3fd6d80ef47";
    hash = "sha256-usLRVAnPWR4+RUSXcTL43cV3JnEtIcTysYdCppL0jxM=";
    mods = map curseforgeMod [
      # Fabric API
      {
        projectId = 306612;
        fileId = 3516413;
        hash = "sha256-PfjdUD81qgrJ+ritn5o2n9/QsatUSvGaPWJtlI+0WGw=";
      }
      # Cloth Config
      {
        projectId = 319057;
        fileId = 3521274;
        hash = "sha256-R5LjfYnIEKCEoJ3jGgxbI6ArhhSTyVK4c/CccsfcnUw=";
      }
      # REI
      {
        projectId = 310111;
        fileId = 3337658;
        hash = "sha256-HMQ55cGxMnL+BHvG/IkbLiMcFuL1wEBmotip3E//aaU=";
      }
    ] ++ map modrinthMod [
      # Sodium
      {
        projectId = "AANobbMI";
        version = "mc1.16.5-0.2.0";
        hash = "sha256-HiBg1M+OPZHbBa95t/KTnx1b0bnLrLJ3MKqeI7NGgy0=";
      }
      # Mod Menu
      {
        projectId = "mOgUt4GM";
        version = "1.16.22";
        hash = "sha256-bYP08vpv/HbEGGISW6ij0asnfZk1nhn8HUj/A7EV81A=";
      }
    ];
  };
  vanilla10 = minecraft {
    version = "1.10.2";
    sha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
  };
  vanilla12 = minecraft {
    version = "1.12.2";
    sha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
  };
  vanilla16 = minecraft {
    version = "1.16";
    sha1 = "5a157ca1ae150c3acb10afdfe714ba34bf322315";
  };
  curseforge = curseforgeMod {
    projectId = 238222;
    fileId = 3448057;
    hash = "sha256-Q4j9n1sZ2ccjz9DLBznVjvmZlNwNHYeaG1Tr1Zh38go=";
  };
  modrinth = modrinthMod {
    projectId = "AANobbMI";
    version = "mc1.16.5-0.2.0";
    hash = "sha256-HiBg1M+OPZHbBa95t/KTnx1b0bnLrLJ3MKqeI7NGgy0=";
  };
  modpack10 = minecraftFtbModpack {
    id = 25;
    version = 123;
    hash = "sha256-rIK9l8q/WSfaf9nRfDt5A/vTS7Zx+VTPC69JqGHETH4=";
    mcSha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    forgeHash = "sha256-DFB1b0lcYSOJQ2uRN0gVoNkWxNFf4Bb077PbRNnlFkI=";
  };
  modpack12 = minecraftFtbModpack {
    id = 35;
    version = 2059;
    hash = "sha256-9dN7YrKWHdS97gMQGQbNMVjOBMNMg36qMMot47OthAw=";
    mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    forgeHash = "sha256-GPNLYZA+4fIZunpXTbp5zGqg6ZHK/QqTWyLmzPIRuYs=";
  };
}
