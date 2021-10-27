# This file is part of nix-minecraft.

# nix-minecraft is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# nix-minecraft is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with nix-minecraft.  If not, see <https://www.gnu.org/licenses/>.

{ pkgs, lib ? pkgs.lib }:
pkgs.writeShellScriptBin "getMcHash" ''
  test -z $1 && echo "Usage: getMcHash <version>" && exit 1
  curl 'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json' \
    | jq -r ".versions[] | select(.id == \"$1\") | .sha1"
''
