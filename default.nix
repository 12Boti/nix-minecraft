# nix-minecraft: A Minecraft launcher in nix.
# Copyright (C) 2021 12Boti

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
, lib ? pkgs.lib
}:
{
  getMcHash = import ./src/getmchash.nix { inherit pkgs lib; };

  inherit (import ./src/minecraft.nix { inherit pkgs lib; }) minecraft;

  minecraftForge = import ./src/forge.nix { inherit pkgs lib; };

  curseforgeMod = import ./src/curseforge.nix { inherit pkgs lib; };

  minecraftFtbModpack = import ./src/ftb.nix { inherit pkgs lib; };

  minecraftLiteloader = import ./src/liteloader.nix { inherit pkgs lib; };

  minecraftFabric = import ./src/fabric.nix { inherit pkgs lib; };
}
