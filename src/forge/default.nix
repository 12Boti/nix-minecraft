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
  inherit (lib) mkOption mkIf types;
  versionStr = "${config.minecraft.version}-${config.forge.version}";

  downloaded = import ../download-module.nix {
    inherit pkgs lib;
    name = "forge-${versionStr}";
    enabled = config.forge.version != null;
    nativeBuildInputs = with pkgs; [ jre unzip ];
    hash = config.forge.hash;
    jsonnetFile = ../jsonnet/forge.jsonnet;
    scriptBefore = ''
      curl -L -o installer.jar \
        'https://maven.minecraftforge.net/net/minecraftforge/forge/${versionStr}/forge-${versionStr}-installer.jar'
          
      java -jar installer.jar --extract
      forgeJar=$(find -name 'forge-*.jar')
      if [ -n "$forgeJar" ]
      then
        JSONNET_ARGS="--tla-code have_forge_jar=true"
        cp $forgeJar $out/forge.jar
      else
        JSONNET_ARGS="--tla-code have_forge_jar=false"
      fi

      files="$(unzip -Z -1 installer.jar)"
      if [[ "$files" =~ "version.json" ]]
      then
        unzip -p installer.jar version.json > version.json
      else
        unzip -p $forgeJar version.json > version.json
      fi
      unzip -p installer.jar install_profile.json > install_profile.json
      if jq -e 'has("processors") and .processors != []' install_profile.json
      then
        cp installer.jar $out/installer.jar
        # need to get the libraries for the installer too
        jq -ns 'inputs | .[0] + {libraries: (.[0].libraries + (.[1].libraries | .[] += {installerOnly: true}))}' \
          version.json install_profile.json > orig.json
      else
        # no need to call the installer
        mv version.json orig.json
      fi
    '';
  };
in
{
  options.forge = {
    version = mkOption {
      default = null;
      example = "14.23.5.2855";
      description = ''
        The version of forge to use.
        See the available versions here: https://files.minecraftforge.net/net/minecraftforge/forge/
      '';
      type = types.nullOr types.nonEmptyStr;
    };
    hash = mkOption {
      description = ''
        The hash of the forge version.
        Leave it empty to have nix tell you what to use.
      '';
      type = types.str;
    };
  };

  config.internal = downloaded.module;

  config.postInstall =
    let
      installer = "${downloaded.drv}/installer.jar";
      mc = config.minecraft.version;
      mappings = pkgs.fetchurl {
        inherit (config.internal.clientMappings) url sha1;
      };
    in
    mkIf (config.forge.version != null && builtins.pathExists installer)
      ''
        # setup environment for forge installer
        cd $(mktemp -d)
        echo '{}' > launcher_profiles.json
        mkdir -p versions/${mc}
        jsonfile="$(find ${mcversions}/history -name '${mc}.json')"
        ln -s "$jsonfile" versions/${mc}/${mc}.json
        ln -s \
          $out/libraries/net/minecraft/client/${mc}/client-${mc}.jar \
          versions/${mc}/${mc}.jar
        cp -rL --no-preserve=all $out/libraries libraries

        # patch installertools to work offline
        installertools=libraries/net/minecraftforge/installertools/*/installertools-*.jar
        echo "patching installertools ($installertools)"
        cp ${mappings} mappings.txt
        cp ${./DownloadMojmaps.java} DownloadMojmaps.java
        ${pkgs.jdk}/bin/javac -cp $installertools DownloadMojmaps.java
        mkdir -p net/minecraftforge/installertools
        cp DownloadMojmaps.class net/minecraftforge/installertools
        ${pkgs.zip}/bin/zip -urv $installertools net/minecraftforge/installertools/DownloadMojmaps.class

        # update installertools hash in installer
        hash=$(sha1sum $installertools | cut -d' ' -f1)
        cp --no-preserve=all ${installer} installer.jar
        ${pkgs.unzip}/bin/unzip -p installer.jar install_profile.json \
          | ${pkgs.jq}/bin/jq '
            (
              .libraries[]
              | select(.name | startswith("net.minecraftforge:installertools"))
              | .downloads.artifact
            ) += {sha1:"'$hash'"}' \
          > install_profile.json
        ${pkgs.zip}/bin/zip -u installer.jar install_profile.json

        # delete signature to allow running modified installer
        ${pkgs.zip}/bin/zip -d installer.jar META-INF/FORGE.SF

        # run the installer
        ${pkgs.kotlin}/bin/kotlin \
          -cp installer.jar ${./forge.kts} \
          | tee installer_output
        test "$(tail -n 1 installer_output)" = "true"

        # copy the files modified by the installer
        rm $out/libraries
        mv libraries $out/libraries
        rm $out/libraries/net/minecraft/client/${mc}/client-${mc}.jar
        ln -s $out/libraries/net/minecraft/client/${mc}-*/client-${mc}-*-extra.jar $out/libraries/net/minecraft/client/${mc}/client-${mc}.jar
      '';
}
