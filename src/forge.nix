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
  cfg = config.forge;
  versionStr = "${config.minecraft.version}-${cfg.version}";
in
{
  options.forge = {
    version = mkOption {
      default = null;
      example = "14.23.5.2855";
      description = "The version of forge to use.";
      type = types.nullOr types.nonEmptyStr;
    };
    hash = mkOption {
      description = "The hash of the forge version.";
      type = types.str;
    };
  };

  config =
    let
      package = pkgs.runCommand "forge-${cfg.version}"
        {
          nativeBuildInputs = with pkgs; [ jsonnet jre unzip jq curl ];
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          outputHash = cfg.hash;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        }
        ''
          curl -L -o installer.jar \
            'https://maven.minecraftforge.net/net/minecraftforge/forge/${versionStr}/forge-${versionStr}-installer.jar'
          
          java -jar installer.jar --extract
          forgeJar="forge-*.jar"

          files="$(unzip -Z -1 installer.jar)"
          if [[ "$files" =~ "version.json" ]]
          then
            unzip -p installer.jar version.json > orig.json
          else
            unzip -p $forgeJar version.json > orig.json
          fi

          mkdir -p $out

          jsonnet -J ${./jsonnet} -m $out \
            --tla-str-file orig_str=orig.json \
            ${./jsonnet/forge.jsonnet}
          
          jq -r '.[] | .url + " " + .path' < $out/downloads.json | \
          while read url path
          do
            curl -L -o "$out/$path" "$url"
          done

          cp $forgeJar $out/forge.jar

          rm $out/downloads.json
        '';
      module =
        builtins.fromJSON
          (builtins.readFile "${package}/package.json");
    in
    mkIf (cfg.version != null)
      {
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
