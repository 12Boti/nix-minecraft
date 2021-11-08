{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
with import ./. { };
{
  inherit getMcHash;

  forge10 = minecraftForge {
    version = "1.10.2-12.18.3.2511";
    mcSha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    hash = "sha256-0+GVE5esm0qCYojPmh6YMYLvhA3nJn5Ut1cdJoNvv4k=";
  };
  forge12 = minecraftForge {
    version = "1.12.2-14.23.5.2855";
    mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
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
  liteloader10 = minecraftLiteloader {
    url = "http://dl.liteloader.com/redist/1.10.2/liteloader-installer-1.10.2-00.jar";
    mcSha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    hash = "sha256-PXSSqIB5WfoPXdnHOFDwqhV3oBG0acc+mTAqZ09Xa9M=";
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
    hash = "sha256-KLJuE5ey/dxaDkO3mkS2Eink0m5qV/Ti6XLG5I1OcPU=";
    mods = map pkgs.fetchurl [
      # Extended Hotbar
      {
        url = "https://github.com/DenWav/ExtendedHotbar/releases/download/1.2.0/mod-extendedhotbar-1.2.0-mc1.12.2.litemod";
        hash = "sha256-CyB7jypxXq41wAfb/t1RCsxaS8uZZjAl/h531osq0Fc=";
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
  mod = curseforgeMod {
    projectId = 238222;
    fileId = 3448057;
    hash = "sha256-Q4j9n1sZ2ccjz9DLBznVjvmZlNwNHYeaG1Tr1Zh38go=";
  };
  modpack10 = minecraftFtbModpack {
    id = 25;
    version = 123;
    hash = "sha256-rIK9l8q/WSfaf9nRfDt5A/vTS7Zx+VTPC69JqGHETH4=";
    mcSha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    forgeHash = "sha256-0+GVE5esm0qCYojPmh6YMYLvhA3nJn5Ut1cdJoNvv4k=";
  };
  modpack12 = minecraftFtbModpack {
    id = 35;
    version = 2059;
    hash = "sha256-9dN7YrKWHdS97gMQGQbNMVjOBMNMg36qMMot47OthAw=";
    mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    forgeHash = "sha256-3Z4QA7WbxCYJxvzReb4VfxcyCt9WzHL0z64FMxzk6nk=";
  };
}
