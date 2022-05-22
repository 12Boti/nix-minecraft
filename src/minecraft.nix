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

{ config, pkgs, lib, mcversions, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.minecraft;
in
{
  imports = [
    ./runners.nix
    ./downloaders.nix
  ];

  options.minecraft = {
    version = mkOption {
      example = "1.18";
      description = "The version of minecraft to use.";
      type = types.nonEmptyStr;
      default = config.internal.requiredMinecraftVersion;
    };
  };

  config.internal =
    let
      normalized =
        pkgs.runCommand "package.json"
          {
            nativeBuildInputs = [ pkgs.jsonnet ];
          }
          ''
            jsonfile="$(find ${mcversions}/history -name '${cfg.version}.json')"
            jsonnet -J ${./jsonnet} --tla-str-file orig_str="$jsonfile" -o $out \
              ${./jsonnet/normalize.jsonnet}
          '';
      module = lib.importJSON normalized;
    in
    # tell nix what attrs to expect to avoid infinite recursion
    {
      inherit (module) minecraftArgs jvmArgs assets javaVersion libraries mainClass;
      clientMappings = module.clientMappings or { };
    };
}
