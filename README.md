# nix-minecraft
A Minecraft launcher in nix.

Support for:
- [forge](https://github.com/MinecraftForge)
- [fabric](https://fabricmc.net/)
- liteloader
- modpacks from 
  - [curseforge](https://www.curseforge.com/minecraft/modpacks)
  - [feed the beast](https://www.feed-the-beast.com/)

Fully declarative and reproducible.

Usable either standalone, or as a [home-manager](https://github.com/nix-community/home-manager) module.

## Requirements
Nix with [flake](https://nixos.wiki/wiki/Flakes) support.

## Standalone usage
Run:
```console
$ nix flake init -t github:12Boti/nix-minecraft
```
This will create a `flake.nix` file in the current directory.
You can customize it, all options are documented at https://12boti.github.io/nix-minecraft

To start minecraft, just
```console
$ nix run
```

## Usage with home-manager
Add
```nix
inputs.nix-minecraft.url = "github:12Boti/nix-minecraft";
```
to your flake inputs. The home-manager module will be at
`nix-minecraft.nixosModules.home-manager.minecraft`

Write your configuration at `programs.minecraft.versions.<name>`, where `<name>`
is some string identifying that installation. You can have as many installations as you want.

If you want some options to apply for all installations, put them in `programs.minecraft.shared`

All installations will have a directory at `${programs.minecraft.basePath}/<name>/`
(by default `.minecraft/<name>/`), which contains the game directory `gamedir`
(where your worlds and settings are saved) and an executable named `run` which
starts Minecraft.

### Example
```nix
{
  programs.minecraft = {
    shared = {
      username = "NixDude";
    };
    versions = {
      "vanilla18" = {
        minecraft.version = "1.18";
      };
      "projectozone3" = {
        modpack.curseforge = {
          projectId = 256289;
          fileId = 3590506;
          hash = "sha256-sm1JihpKd8OeW5t8E4+/wCgAnD8/HpDCLS+CvdcNmqY=";
        };
        forge.hash = "sha256-5lQKotcSIgRyb5+MZIEE1U/27rSvwy8Wmb4yCagvsbs=";
      };
    };
  };
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
