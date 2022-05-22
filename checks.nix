{ pkgs
, mkMinecraft
}:
let
  inherit (pkgs) lib fetchurl;
  shared = {
    username = "NixDude";
    gamedir = "./gamedir";
  };
in
lib.mapAttrs (_: m: mkMinecraft (shared // m))
{
  forge10 = {
    minecraft.version = "1.10.2";
    forge = {
      version = "12.18.3.2511";
      hash = "sha256-4ILrLyyp2BnMmkuZ92Y2QqZpv4yYFzOsgcBWNW2QAcM=";
    };
  };
  forge12 = {
    minecraft.version = "1.12.2";
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
  forge18 = {
    minecraft = {
      version = "1.18.2";
    };
    forge = {
      version = "40.1.0";
      hash = "sha256-MxvdrceY7/o+ZsuIJIr/ZrqZpXXYwX09k4oG4fVboDU=";
    };
  };
  liteloader10 = {
    liteloader = {
      url = "http://dl.liteloader.com/redist/1.10.2/liteloader-installer-1.10.2-00.jar";
      hash = "sha256-qoeFTNhO9O11L7WHmA4l5bdsFO2hU0jkEfOndEfSfrY=";
    };
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
    mods.manual = map fetchurl [
      # Extended Hotbar
      {
        url = "https://github.com/DenWav/ExtendedHotbar/releases/download/1.2.0/mod-extendedhotbar-1.2.0-mc1.12.2.litemod";
        hash = "sha256-CyB7jypxXq41wAfb/t1RCsxaS8uZZjAl/h531osq0Fc=";
      }
    ];
  };
  fabric16 = {
    minecraft.version = "1.16.5";
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
    minecraft.version = "1.18";
    fabric = {
      version = "0.12.12";
      hash = "sha256-RTq/itGPUUiRzG/wjDiW6YAALFB7Pe7DWFIOdClZG14=";
    };
  };
  vanilla10 = {
    minecraft.version = "1.10.2";
  };
  vanilla12 = {
    minecraft.version = "1.12.2";
  };
  vanilla16 = {
    minecraft.version = "1.16";
  };
  vanilla18 = {
    minecraft.version = "1.18";
  };
  ftb-skyfactory-3 = {
    modpack.ftb = {
      id = 25;
      version = 123;
      hash = "sha256-BgF7qlhiWdcY9nzWbYlmDas8ynJP88/x0KnNsl+7Gxs=";
    };
    forge.hash = "sha256-4ILrLyyp2BnMmkuZ92Y2QqZpv4yYFzOsgcBWNW2QAcM=";
  };
  ftb-revelation = {
    modpack.ftb = {
      id = 35;
      version = 2059;
      hash = "sha256-P7uf1EhNo4xooQsQ8b49K4bdxZk+twGnp+llG9bo/Us=";
    };
    forge.hash = "sha256-C63CarysEFLYKqlzfFJpbgUNgP19ymi9pce5zKPmNH4=";
  };
  project-ozone-3 = {
    modpack.curseforge = {
      projectId = 256289;
      fileId = 3590506;
      hash = "sha256-sm1JihpKd8OeW5t8E4+/wCgAnD8/HpDCLS+CvdcNmqY=";
    };
    forge.hash = "sha256-5lQKotcSIgRyb5+MZIEE1U/27rSvwy8Wmb4yCagvsbs=";
  };
  all-of-fabric-5 = {
    modpack.curseforge = {
      projectId = 548076;
      fileId = 3671527;
      hash = "sha256-SI6uY/LFWjOV3UepolsymI77N1zrwgP4Fx6O7oD8tpo=";
    };
    fabric.hash = "sha256-pZlF6NQ/1w0iJAsP4gbUitB8kju+TBKFrFojPFmjGTU=";
  };
  rlcraft = {
    modpack.curseforge = {
      projectId = 285109;
      fileId = 3575903;
      hash = "sha256-6IE5/+gy6gFTlIxMVAXVM4inusovbgY6MZVxnQLKtkM=";
    };
    forge.hash = "sha256-5lQKotcSIgRyb5+MZIEE1U/27rSvwy8Wmb4yCagvsbs=";
  };
  all-in-one = {
    modpack.curseforge = {
      projectId = 439293;
      fileId = 3737061;
      hash = "sha256-qYZ9EPPuN0NC3mD/EA/LqyXwTpWnA8eFZl5ghGtxpik=";
    };
    forge.hash = "sha256-ofBKfALgtOVaonZVfwDPZFLaxyW0DZjcpgTqkUkv+kQ=";
  };
  all-the-mods-7 = {
    modpack.curseforge = {
      projectId = 426926;
      fileId = 3797783;
      hash = "sha256-u+WQuSIWKXkEqLFOehe40YWt5hwdozYtQthm6Pezu0k=";
    };
    forge.hash = "sha256-UWg/WJZ6mBUTnRUnJR71tgcgbjFV1mbsdx89einW440=";
  };
}
