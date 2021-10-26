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
let
  os =
    let
      p = pkgs.stdenv.hostPlatform;
    in
    if p.isLinux then "linux"
    else if p.isWindows then "windows"
    else if p.isMacOS then "osx"
    else throw "unsupported OS";

  fetchJson = { url, sha1 ? "", sha256 ? "", hash ? "" }:
    let
      file = pkgs.fetchurl {
        inherit url sha1 sha256 hash;
      };
      json = builtins.readFile file;
    in
    builtins.fromJSON json;

  # downloads information about a specific version of minecraft
  getMc = { version, sha1 }:
    fetchJson {
      url = "https://launchermeta.mojang.com/v1/packages/${sha1}/${version}.json";
      inherit sha1;
    };

  isAllowed = rules:
    (
      builtins.elem
        {
          action = "allow";
          os.name = os;
        }
        rules
    )
    || (
      (
        builtins.elem
          {
            action = "allow";
          }
          rules
      ) && (
        !builtins.elem
          {
            action = "disallow";
            os.name = os;
          }
          rules
      )
    );

  # downloads the java and native libraries in the list
  downloadLibs = mc:
    let
      libs = mc.libraries;
      javaLibs =
        map
          (
            javaLib:
            let
              a = javaLib.downloads.artifact;
            in
            pkgs.fetchurl
              {
                inherit (a) url sha1;
              }
            // lib.optionalAttrs (a ? path) {
              passthru = {
                path = a.path;
              };
            }

          )
          (
            builtins.filter
              (
                x:
                x ? downloads.artifact
                && x.downloads.artifact.url != ""
                && (x ? rules -> isAllowed x.rules)
              )
              libs
          )
        ++ [ (pkgs.fetchurl { inherit (mc.downloads.client) url sha1; }) ];
      nativeLibs =
        map
          (
            nativeLib:
            let
              classifier = nativeLib.natives.${os};
              a = nativeLib.downloads.classifiers.${classifier};
              zip =
                pkgs.fetchurl {
                  inherit (a) url sha1;
                };
            in
            pkgs.runCommand "unpack-zip" { } ''
              ${pkgs.unzip}/bin/unzip ${zip} -d $out
              rm -rf $out/META-INF
            ''
          )
          (
            builtins.filter
              (
                x: x ? natives.${os} && (x ? rules -> isAllowed x.rules)
              )
              libs
          );
    in
    { inherit javaLibs nativeLibs; };

  downloadAssets = assetIndexInfo:
    let
      assetIndexFile = pkgs.fetchurl { inherit (assetIndexInfo) url sha1; };
      assetIndex = builtins.fromJSON (builtins.readFile assetIndexFile);
      objectScripts = lib.mapAttrsToList
        (
          object: { hash, size }:
            let
              shorthash = builtins.substring 0 2 hash;
              asset = pkgs.fetchurl {
                sha1 = hash;
                url = "https://resources.download.minecraft.net/${shorthash}/${hash}";
              };
            in
            ''
              mkdir -p $out/objects/${shorthash}
              ln -sf ${asset} $out/objects/${shorthash}/${hash}
            ''
        )
        assetIndex.objects;
      script = (lib.concatStringsSep "\n" objectScripts) + ''
        mkdir -p $out/indexes
        ln -s ${assetIndexFile} $out/indexes/${assetIndexInfo.id}.json
      '';
    in
    pkgs.runCommand "symlink-assets" { } script;

  minecraftFromPkg =
    {
      # json containing information about this version of minecraft
      pkg
      # extra .jar files to add to classpath
    , extraJars ? [ ]
      # extra files to be copied to the game directory on launch
    , extraGamedirFiles ? null
      # run tests if true
    , doCheck ? false
    }:
    let
      assets = downloadAssets pkg.assetIndex;

      downloaded = downloadLibs pkg;
      inherit (downloaded) nativeLibs;
      javaLibs = downloaded.javaLibs ++ extraJars;

      nativeLibsDir = pkgs.symlinkJoin {
        name = "minecraft-natives";
        paths =
          nativeLibs
          ++ lib.optionals (os == "linux") [
            "${pkgs.libpulseaudio}/lib"
            "${pkgs.xlibs.libXxf86vm}/lib"
          ];
      };

      classpath = lib.concatStringsSep ":" javaLibs;
      javaLibsDir =
        let
          script = lib.concatStringsSep "\n"
            (
              map
                (
                  x: ''
                    mkdir -p $out/${dirOf x.passthru.path}
                    ln -sf ${x} $out/${x.passthru.path}
                  ''
                )
                (
                  builtins.filter
                    (x: x.passthru ? path)
                    javaLibs
                )
            );
        in
        pkgs.runCommand "symlink-jars" { } script;

      arguments =
        pkg.minecraftArguments
          or
          (
            lib.concatStringsSep " " (
              map
                (
                  x:
                  if builtins.isString x then x
                  else if isAllowed x.rules then
                    if builtins.isList x.value then lib.concatStringsSep " " x.value
                    else x.value
                  else ""
                )
                (pkg.arguments.jvm ++ pkg.arguments.game)
            )
          );
      jre = {
        "8" = pkgs.jre8;
        "16" = pkgs.jre;
      }.${toString pkg.javaVersion.majorVersion};
      runner = pkgs.writeShellScript "minecraft-runner" ''
        out='%OUT%'
        usage="Usage: $0 <username> [<gamedir>]"
        test $# -eq 0 && echo $usage && exit 1
        test "$1" = "-h" -o "$1" = "--help" && echo $usage && exit 1
        auth_player_name="$1"
        version_name='${pkg.id}'
        game_directory="''${2:-./gamedir}"
        ${lib.optionalString
        (extraGamedirFiles != null)
        ''
          if [ -d "$game_directory/mods" -a -d "${extraGamedirFiles}/mods" ]; then
            diff -q "$game_directory/mods" "${extraGamedirFiles}/mods" \
              || echo "warning: mods folder already exists, remove it in case of conflicts and try again"
          fi
          echo "copying files to game directory ($game_directory)"
          rsync -rl --ignore-existing --chmod=755 --info=skip2,name ${extraGamedirFiles}/ "$game_directory"
        ''}
        assets_root="$out/assets"
        assets_index_name='${pkg.assetIndex.id}'
        auth_uuid='1234'
        auth_access_token='REPLACEME'
        user_type='mojang'
        version_type='${pkg.type}'
        # clear all other environment variables (yay purity)
        # keep:
        #  DISPLAY and XAUTHORITY for graphics (x11)
        #  XDG_RUNTIME_DIR for sound (pulseaudio?)
        exec env -i \
          LD_LIBRARY_PATH="$out/natives" \
          DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" \
          XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
          ${jre}/bin/java \
          -Djava.library.path="$out/natives" \
          -classpath '${classpath}' \
          '${pkg.mainClass}' \
          ${arguments}
      '';
    in
    pkgs.runCommand
      "minecraft"
      { }
      (
        ''
          echo setting up environment
          mkdir -p $out
          ln -s ${javaLibsDir} $out/libraries
          ln -s ${nativeLibsDir} $out/natives
          ln -s ${assets} $out/assets
          ${lib.optionalString
          (extraGamedirFiles != null)
          "ln -s ${extraGamedirFiles} $out/gamedir"}
          echo creating runner script
          mkdir -p $out/bin
          sed "s|%OUT%|$out|" ${runner} > $out/bin/minecraft
          chmod +x $out/bin/minecraft
        ''
        + lib.optionalString doCheck ''
          echo running checks
          ${pkgs.xdummy}/bin/xdummy :3 \
            -ac -nolisten unix +extension GLX +xinerama +extension RANDR +extension RENDER &
          XPID=$!
          sleep 1
          echo running minecraft
          export DISPLAY=:3
          $out/bin/minecraft &
          MCPID=$!
          # wait until window visible
          timeout 5s ${pkgs.xdotool}/bin/xdotool search --sync --onlyvisible --pid $MCPID
          ${pkgs.xdotool}/bin/xdotool windowclose
          wait $MCPID
          kill $XPID
        ''
      );
in
{
  getMcHash = pkgs.writeShellScriptBin "getMcHash" ''
    test -z $1 && echo "Usage: getMcHash <version>" && exit 1
    curl 'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json' \
      | jq -r ".versions[] | select(.id == \"$1\") | .sha1"
  '';

  minecraft =
    { version
    , sha1 # use `getMcHash <version>`
    , extraGamedirFiles ? null
    }:
    minecraftFromPkg {
      pkg = getMc { inherit version sha1; };
      inherit extraGamedirFiles;
    };

  minecraftForge =
    { version, mcSha1, hash, mods ? [ ], extraGamedirFiles ? null }:
    let
      installer = pkgs.fetchurl {
        url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar";
        inherit hash;
      };

      forgeJar = pkgs.runCommand "forge.jar" { } ''
        ${pkgs.jre}/bin/java -jar ${installer} --extract
        cp *.jar $out
      '';
      pkg =
        let
          versionJsonFile = pkgs.runCommand "forge-version.json" { } ''
            ${pkgs.unzip}/bin/unzip -p ${installer} version.json > $out
          '';
          forge = builtins.fromJSON (builtins.readFile versionJsonFile);
          mc = getMc { version = forge.inheritsFrom; sha1 = mcSha1; };
        in
        lib.zipAttrsWith
          (
            name: values:
              # concat lists, replace other values
              if lib.all lib.isList values
              then lib.concatLists values
              else lib.head values
          )
          [ forge mc ];
    in
    minecraftFromPkg {
      inherit pkg;
      extraJars = [ forgeJar ];
      extraGamedirFiles = pkgs.symlinkJoin {
        name = "extra-gamedir";
        paths =
          lib.optional (extraGamedirFiles != null) extraGamedirFiles
          ++ [
            (
              pkgs.linkFarm
                "mods"
                (map (m: { name = "mods/${m.name}"; path = m; }) mods)
            )
          ];
      };
    };

  curseforgeMod =
    { projectId, fileId, hash }:
    pkgs.runCommandLocal
      "curseforge-mod-${toString projectId}-${toString fileId}.jar"
      {
        outputHash = hash;
        outputHashAlgo = "sha256";
        buildInputs = [ pkgs.curl pkgs.jq ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        url=$(
        curl 'https://addons-ecs.forgesvc.net/api/v2/addon/${toString projectId}/files' \
        | jq -r '.[] | select(.id == ${toString fileId}) | .downloadUrl'
        )
        curl -L -o "$out" "$url"
      '';
}
