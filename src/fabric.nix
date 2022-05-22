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
  inherit (lib) mkOption types;
in
{
  options.fabric = {
    version = mkOption {
      default = null;
      example = "0.12.5";
      description = ''
        The version of fabric to use.
        You'll most likely want the latest version from https://github.com/FabricMC/fabric-loader/releases
      '';
      type = types.nullOr types.nonEmptyStr;
    };
    hash = mkOption {
      description = ''
        The hash of the fabric version.
        Leave it empty to have nix tell you what to use.
      '';
      type = types.str;
    };
  };

  config.internal = (import ./download-module.nix {
    inherit pkgs lib;
    name = "fabric-${config.fabric.version}";
    enabled = config.fabric.version != null;
    hash = config.fabric.hash;
    jsonnetFile = ./jsonnet/download.jsonnet;
    scriptBefore = ''
      curl -L -o orig.json \
        'https://meta.fabricmc.net/v2/versions/loader/${config.minecraft.version}/${config.fabric.version}/profile/json'
    '';
  }).module;
}
