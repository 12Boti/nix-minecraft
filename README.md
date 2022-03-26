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
