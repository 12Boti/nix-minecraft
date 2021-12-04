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
{ projectId, version, hash }:
let
  versions = lib.pipe
    { url = "https://api.modrinth.com/api/v1/mod/${projectId}/version"; }
    [ builtins.fetchurl builtins.readFile builtins.fromJSON ];
  versionData = lib.findFirst
    (x: x.version_number == version)
    (throw "version ${version} not found for project ${projectId}")
    versions;
in
pkgs.fetchurl {
  name = "modrinth-mod-${projectId}-${version}.jar";
  inherit hash;
  inherit (lib.head versionData.files) url;
}
