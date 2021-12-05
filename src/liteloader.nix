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
  inherit (lib) mkOption mkOverride mkIf types;
  cfg = config.liteloader;
in
{
  options.liteloader = {
    url = mkOption {
      default = null;
      example = "0.12.5";
      description = "The url to download liteloader from.";
      type = types.nullOr types.nonEmptyStr;
    };
    hash = mkOption {
      description = "The hash of the liteloader version.";
      type = types.str;
    };
  };

  config =
    let
      package = pkgs.runCommand "liteloader"
        {
          nativeBuildInputs = with pkgs; [ jsonnet unzip jq curl ];
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          outputHash = config.liteloader.hash;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        }
        ''
          curl -L -o installer.jar '${cfg.url}'
        
          unzip -p installer.jar install_profile.json > orig.json

          mkdir -p $out

          jsonnet -J ${./jsonnet} -m $out \
            --tla-str-file orig_str=orig.json \
            ${./jsonnet/liteloader.jsonnet}
          
          jq -r '.[] | .url + " " + .path' < $out/downloads.json | \
          while read url path
          do
            curl -L -o "$out/$path" "$url"
          done

          rm $out/downloads.json
        '';
      module =
        builtins.fromJSON
          (builtins.readFile "${package}/package.json");
    in
    mkIf (config.liteloader.url != null)
      {
        minecraft.version = module.minecraft.version;
        arguments =
          if module.overrideArguments
          then mkOverride 90 module.arguments
          else module.arguments;
        mainClass = mkOverride 90 module.mainClass;
        libraries = map
          (lib:
            if lib ? path
            then lib // { path = "${package}/${lib.path}"; }
            else lib
          )
          module.libraries;
      };
}
