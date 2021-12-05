{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
, lib ? pkgs.lib
}:
with import ./. { };
lib.mapAttrs (_: minecraft)
{
  forge10 = {
    minecraft = {
      version = "1.10.2";
      sha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    };
    forge = {
      version = "12.18.3.2511";
      hash = "sha256-2RHif14tlxUJVi6V8XibSVRxQI/9j1WMZh3WJDz4Dqw=";
    };
  };
  forge12 = {
    minecraft = {
      version = "1.12.2";
      sha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    };
    forge = {
      version = "14.23.5.2855";
      hash = "sha256-PgsJtE3ojszGSXzAxHVPdZyHkYUaiyTseOjDk4W/sVc=";
    };
    mods.curseforge = [
      # JEI
      {
        projectId = 238222;
        fileId = 3043174;
        hash = "sha256-nbwsDsjCiCH91dykh5CQiVAWB+4lwOhHDEPJ/QvRIFM=";
      }
    ];
    mods.modrinth = [
      # Durability101
      {
        projectId = "Yt3rEMOb";
        version = "Forge-1.12-0.0.4";
        hash = "sha256-0KiiNfk96r18e7y+bPK9CG56DwhmuNhfVfxtyP+tvNY=";
      }
    ];
  };
  liteloader10 = {
    liteloader = {
      url = "http://dl.liteloader.com/redist/1.10.2/liteloader-installer-1.10.2-00.jar";
      hash = "sha256-Ir/Qa++P86x8nvVJrj3xG2OGn5Ykrufw8tmz9IqMSo8=";
    };
    minecraft.sha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    mods.curseforge = [
      # Armors HUD Revived
      {
        projectId = 244537;
        fileId = 2317559;
        hash = "sha256-Q+s8EqmBizXpgGnel2PXWGLRPmVidWvMqQVmctbEK4o=";
      }
    ];
  };
  liteloader12 = {
    liteloader = {
      url = "http://jenkins.liteloader.com/job/LiteLoaderInstaller%201.12.2/lastSuccessfulBuild/artifact/build/libs/liteloader-installer-1.12.2-00-SNAPSHOT.jar";
      hash = "sha256-2gCsyXqui9y/WlBm3aSUElpNooATuEqbv5rAbETKA8U=";
    };
    minecraft.sha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    mods.manual = map pkgs.fetchurl [
      # Extended Hotbar
      {
        url = "https://github.com/DenWav/ExtendedHotbar/releases/download/1.2.0/mod-extendedhotbar-1.2.0-mc1.12.2.litemod";
        hash = "sha256-CyB7jypxXq41wAfb/t1RCsxaS8uZZjAl/h531osq0Fc=";
      }
    ];
  };
  fabric16 = {
    minecraft = {
      version = "1.16.5";
      sha1 = "66935fe3a8f602111a3f3cba9867d3fd6d80ef47";
    };
    fabric = {
      version = "0.12.5";
      hash = "sha256-Rq+NQszz3QYt1PrjyNAW+SSsXJ3vq6V3A5Zp7/0qMHo=";
    };
    mods.curseforge = [
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
    ];
    mods.modrinth = [
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
  vanilla10 = {
    minecraft = {
      version = "1.10.2";
      sha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    };
  };
  vanilla12 = {
    minecraft = {
      version = "1.12.2";
      sha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    };
  };
  vanilla16 = {
    minecraft = {
      version = "1.16";
      sha1 = "5a157ca1ae150c3acb10afdfe714ba34bf322315";
    };
  };
  vanilla18 = {
    minecraft = {
      version = "1.18";
      sha1 = "cdd1c0f485c0ea5a5aae60d4e62d316b2141f227";
    };
  };
  modpack10 = {
    ftbModpack = {
      id = 25;
      version = 123;
      hash = "sha256-rIK9l8q/WSfaf9nRfDt5A/vTS7Zx+VTPC69JqGHETH4=";
    };
    minecraft.sha1 = "a86a4eaacfee738c8d609baf6d414175f94c26f6";
    forge.hash = "sha256-2RHif14tlxUJVi6V8XibSVRxQI/9j1WMZh3WJDz4Dqw=";
  };
  modpack12 = {
    ftbModpack = {
      id = 35;
      version = 2059;
      hash = "sha256-9dN7YrKWHdS97gMQGQbNMVjOBMNMg36qMMot47OthAw=";
    };
    minecraft.sha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
    forge.hash = "sha256-PgsJtE3ojszGSXzAxHVPdZyHkYUaiyTseOjDk4W/sVc=";
  };
}
