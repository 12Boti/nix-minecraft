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

{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.ftbModpack;

  json = lib.pipe
    {
      url = "https://api.modpacks.ch/public/modpack/${toString cfg.id}/${toString cfg.version}";
      inherit (cfg) hash;
    }
    [ pkgs.fetchurl builtins.readFile builtins.fromJSON ];

  files = map
    (f: {
      path = "${f.path}/${f.name}";
      source = pkgs.fetchurl {
        inherit (f) sha1;
        url = builtins.replaceStrings [ " " ] [ "%20" ] f.url;
        name = lib.strings.sanitizeDerivationName f.name;
        curlOpts = "--globoff"; # do not misinterpret [] brackets
      };
    })
    (builtins.filter (f: !f.serveronly) json.files);

  forgeVersion = (lib.findFirst
    (t: t.name == "forge")
    (throw "forge not found in modpack targets")
    json.targets).version;

  mcVersion = (lib.findFirst
    (t: t.name == "minecraft")
    (throw "minecraft not found in modpack targets")
    json.targets).version;
in
{
  options.ftbModpack = {
    id = mkOption {
      default = null;
      type = types.nullOr types.int;
    };
    version = mkOption {
      type = types.int;
    };
    hash = mkOption {
      type = types.str;
    };
  };

  config = mkIf (cfg.id != null) {
    minecraft.version = mcVersion;
    forge.version = forgeVersion;
    extraGamedirFiles = files;
  };
}
