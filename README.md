# nix-minecraft
A Minecraft launcher in nix.

## Usage
Import the `default.nix` in this repository in any way you want (vendoring, [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), [nix flakes](https://nixos.wiki/wiki/Flakes), [niv](https://github.com/nmattia/niv), `builtins.fetchTarball`, ...).

### Vanilla
Call `minecraft` with a `version` and a `sha1`. You can get the `sha1` by using the `getMcHash` script.
Example:
```sh
$ nix run -f path/to/default.nix getMcHash 1.12.2
f07e0f1228f79b9b04313fc5640cd952474ba6f5
```
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
You can leave `hash` empty and nix will tell you what to use.

Example:
Save as `myminecraft.nix`:
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftForge curseforgeMod;
in
minecraftForge {
  version = "1.12.2-14.23.5.2855";
  mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
  hash = "";
}
```
```sh
$ nix run -f myminecraft.nix . NixDude ./mygamedir
error: hash mismatch in fixed-output derivation '/nix/store/m50zdpi4iywmpa1839kmmkj4s5a9gl2w-forge-1.12.2-14.23.5.2855-installer.jar.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-x/vHOOXwdi6KbSJdmF2chaN2TI3dxq6a+4EpA63KX8k=
```
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftForge curseforgeMod;
in
minecraftForge {
  version = "1.12.2-14.23.5.2855";
  mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
  hash = "sha256-x/vHOOXwdi6KbSJdmF2chaN2TI3dxq6a+4EpA63KX8k=";
}
```
```sh
$ nix run -f myminecraft.nix . NixDude ./mygamedir # it works now
```
Let's add some mods!
For every mod, call `curseforgeMod` with `projectId`, `fileId`, and `hash`. (I used the nix builtin `map` here to be more concise)

You can get the `projectId` on the curseforge description page, on the right (example: https://www.curseforge.com/minecraft/mc-mods/jei).

The `fileId` is in the download link for that specific version. (example download link: https://www.curseforge.com/minecraft/mc-mods/jei/download/3043174)

Again, leave the hash empty to have nix tell you.
```nix
let
  inherit (import ./path/to/default.nix {}) minecraftForge curseforgeMod;
in
minecraftForge {
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
  forgeHash = "sha256-3Z4QA7WbxCYJxvzReb4VfxcyCt9WzHL0z64FMxzk6nk=";
}
```
Note: both downloading and starting modpacks takes a long time, be patient!

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
  hash = "sha256-PXSSqIB5WfoPXdnHOFDwqhV3oBG0acc+mTAqZ09Xa9M=";
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
