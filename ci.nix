{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
, lib ? pkgs.lib
}:
let
  shared = {
    username = "NixDude";
    gamedir = "./gamedir";
  };
in
with import ./. { };
lib.mapAttrs (_: m: minecraft (shared // m))
{
  forge10 = {
    minecraft = {
      version = "1.10.2";
      hash = "sha256-RJy47jz2Hw77LyyphzFlrvJtCqMZEN0Xp8DdI8ahByk=";
    };
    forge = {
      version = "12.18.3.2511";
      hash = "sha256-4ILrLyyp2BnMmkuZ92Y2QqZpv4yYFzOsgcBWNW2QAcM=";
    };
  };
  forge12 = {
    minecraft = {
      version = "1.12.2";
      hash = "sha256-IUV11B+ydz978Urg6KtfJ8L82+2k7kdLITOUlwOrY/A=";
    };
    forge = {
      version = "14.23.5.2855";
      hash = "sha256-C63CarysEFLYKqlzfFJpbgUNgP19ymi9pce5zKPmNH4=";
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
  # FIXME
  forge18 = {
    minecraft = {
      version = "1.18";
      hash = "sha256-NR2InQHkIFDfYYYyg8haIU1DvcjZD9f9Jfg4RRsX3fI=";
    };
    forge = {
      version = "38.0.17";
      hash = "sha256-rGc1Bth9/Vetr8TnnQwgxrlgx09S84or4IZeirNeW9M=";
    };
  };
  liteloader10 = {
    liteloader = {
      url = "http://dl.liteloader.com/redist/1.10.2/liteloader-installer-1.10.2-00.jar";
      hash = "sha256-qoeFTNhO9O11L7WHmA4l5bdsFO2hU0jkEfOndEfSfrY=";
    };
    minecraft.hash = "sha256-RJy47jz2Hw77LyyphzFlrvJtCqMZEN0Xp8DdI8ahByk=";
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
      hash = "sha256-AfxOgCWliIAMBlMTOMC3gdSShuRB5E6yYYIw0fe8jBM=";
    };
    minecraft.hash = "sha256-IUV11B+ydz978Urg6KtfJ8L82+2k7kdLITOUlwOrY/A=";
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
      hash = "sha256-khV5PppuBrJ15iXRT/UzV1WfTPumYfn6ae2bBJVT0Hk=";
    };
    fabric = {
      version = "0.12.5";
      hash = "sha256-aZvTZJsZeZBxedM2Ip0/NzSdV/AThy6/rI0AlS0Br1A=";
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
  fabric18 = {
    minecraft = {
      version = "1.18";
      hash = "sha256-NR2InQHkIFDfYYYyg8haIU1DvcjZD9f9Jfg4RRsX3fI=";
    };
    fabric = {
      version = "0.12.12";
      hash = "sha256-RTq/itGPUUiRzG/wjDiW6YAALFB7Pe7DWFIOdClZG14=";
    };
  };
  vanilla10 = {
    minecraft = {
      version = "1.10.2";
      hash = "sha256-RJy47jz2Hw77LyyphzFlrvJtCqMZEN0Xp8DdI8ahByk=";
    };
  };
  vanilla12 = {
    minecraft = {
      version = "1.12.2";
      hash = "sha256-IUV11B+ydz978Urg6KtfJ8L82+2k7kdLITOUlwOrY/A=";
    };
  };
  vanilla16 = {
    minecraft = {
      version = "1.16";
      hash = "sha256-I093o0KIr1gd98xZOtM276MOUAI1Nf3R8m9+8viDQDY=";
    };
  };
  vanilla18 = {
    minecraft = {
      version = "1.18";
      hash = "sha256-NR2InQHkIFDfYYYyg8haIU1DvcjZD9f9Jfg4RRsX3fI=";
    };
  };
  modpack10 = {
    ftbModpack = {
      id = 25;
      version = 123;
      hash = "sha256-rIK9l8q/WSfaf9nRfDt5A/vTS7Zx+VTPC69JqGHETH4=";
    };
    minecraft.hash = "sha256-RJy47jz2Hw77LyyphzFlrvJtCqMZEN0Xp8DdI8ahByk=";
    forge.hash = "sha256-4ILrLyyp2BnMmkuZ92Y2QqZpv4yYFzOsgcBWNW2QAcM=";
  };
  modpack12 = {
    ftbModpack = {
      id = 35;
      version = 2059;
      hash = "sha256-9dN7YrKWHdS97gMQGQbNMVjOBMNMg36qMMot47OthAw=";
    };
    minecraft.hash = "sha256-IUV11B+ydz978Urg6KtfJ8L82+2k7kdLITOUlwOrY/A=";
    forge.hash = "sha256-C63CarysEFLYKqlzfFJpbgUNgP19ymi9pce5zKPmNH4=";
  };
}
