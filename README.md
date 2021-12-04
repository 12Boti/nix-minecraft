# nix-minecraft
A Minecraft launcher in nix.

## Usage
Import the `default.nix` in this repository in any way you want (vendoring, [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), [nix flakes](https://nixos.wiki/wiki/Flakes), [niv](https://github.com/nmattia/niv), `builtins.fetchTarball`, ...).

### Vanilla
Call `minecraft` with a `version` and a `sha1`.
You can leave `sha1` empty (`sha1 = ""`) and nix will tell you what to use.
Example:
Save as `myminecraft.nix`:
```nix
let
  inherit (import ./path/to/default.nix {}) minecraft;
in
minecraft {
  version = "1.12.2";
  sha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
}
```
Run it:
```sh
$ nix run -f myminecraft.nix . NixDude ./mygamedir
```
First parameter is your username, second is the game directory (where saves and mods are saved).

### Forge
Call `minecraftForge` with a `version`, `mcSha1`, `hash`, and `mods`.
You can get the version on this site: https://files.minecraftforge.net/net/minecraftforge/forge/.

`mcSha1` is the same as `sha1` for vanilla.
You can leave `hash` empty (`hash = ""`) and nix will tell you what to use.

Example:
Save as `myminecraft.nix`:
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftForge curseforgeMod;
in
minecraftForge {
  version = "1.12.2-14.23.5.2855";
  mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
  hash = "sha256-GPNLYZA+4fIZunpXTbp5zGqg6ZHK/QqTWyLmzPIRuYs=";
}
```
```sh
$ nix run -f myminecraft.nix . NixDude ./mygamedir
```
Let's add some mods!
For every mod, call `curseforgeMod` with `projectId`, `fileId`, and `hash`. (I used the nix builtin `map` here to be more concise)

You can get the `projectId` on the curseforge description page, on the right (example: https://www.curseforge.com/minecraft/mc-mods/jei).

The `fileId` is in the download link for that specific version. (example download link: https://www.curseforge.com/minecraft/mc-mods/jei/download/3043174)

If you want to use [modrinth](https://modrinth.com/), call `modrinthMod` with
a `projectId` from the right side of the mod page (example: https://modrinth.com/mod/sodium),
a `version` from the version column of the versions page (example: https://modrinth.com/mod/sodium/versions),
and a `hash`.

You can also just `fetchurl` any `.jar` file.

Again, leave the hash empty to have nix tell you.
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftForge curseforgeMod;
in
minecraftForge {
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
    # JourneyMap
    {
      projectId = 32274;
      fileId = 2916002;
      hash = "sha256-eLL8gLkdqcxWkVPdZRlZ8Ul9zwVufwiTu1WrWdXw2tk=";
    }
  ];
}
```

### FTB modpacks
Call `minecraftFtbModpack`. Find the `id` at https://www.feed-the-beast.com/modpack. Get the `version` from the versions tab. (You need the version ID, not the version number!)

`mcSha1` is the same as for vanilla.
You can leave `hash` and `forgeHash` empty to have nix tell you.
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftFtbModpack;
in
minecraftFtbModpack {
  id = 35; # FTB Revelation
  version = 2059; # 3.5.0
  hash = "sha256-9dN7YrKWHdS97gMQGQbNMVjOBMNMg36qMMot47OthAw=";
  mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
  forgeHash = "sha256-GPNLYZA+4fIZunpXTbp5zGqg6ZHK/QqTWyLmzPIRuYs=";
}
```
Note: both downloading and starting modpacks takes a long time, be patient!

### Fabric
Call `minecraftFabric`. Don't forget to add the Fabric API to your list of mods,
you'll probably need it!
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftFabric;
in
minecraftFabric {
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
  ];
}
```

### LiteLoader
Works similarly to forge, but instead of the version, use the url of the **jar file**
from https://www.liteloader.com/download.
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftLiteloader curseforgeMod;
in
minecraftLiteloader {
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
}
```

## License
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
