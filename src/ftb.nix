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

{ pkgs, lib ? pkgs.lib }@inputs:
let
  inherit (import ./common.nix inputs) fetchJson;
  minecraftForge = import ./forge.nix inputs;

  fetchUrlToPath =
    { url, name, sha1 ? "", path }:
    let
      escapedName = lib.strings.sanitizeDerivationName name;
      escapedUrl = builtins.replaceStrings [ " " ] [ "%20" ] url;
      f = pkgs.fetchurl {
        inherit sha1;
        url = escapedUrl;
        name = escapedName;
        curlOpts = "--globoff"; # do not misinterpret [] brackets
      };
    in
    pkgs.runCommandLocal f.name { } ''
      mkdir -p "$out/${path}"
      ln -s '${f}' "$out/${path}/${name}"
    '';

  ftbModpackFiles = json:
    pkgs.symlinkJoin {
      name = "ftb-modpack";
      paths = map
        (f: fetchUrlToPath { inherit (f) url name sha1 path; })
        (builtins.filter (f: !f.serveronly) json.files);
    };
in
{ id, version, hash ? "", mcSha1, forgeHash ? "" }:
let
  json = fetchJson {
    url = "https://api.modpacks.ch/public/modpack/${toString id}/${toString version}";
    inherit hash;
  };
  forgeVersion = (lib.findFirst
    (t: t.name == "forge")
    (throw "forge not found in modpack targets")
    json.targets).version;
  mcVersion = (lib.findFirst
    (t: t.name == "minecraft")
    (throw "minecraft not found in modpack targets")
    json.targets).version;
in
minecraftForge {
  version = mcVersion + "-" + forgeVersion;
  inherit mcSha1;
  hash = forgeHash;
  extraGamedirFiles = ftbModpackFiles json;
}
