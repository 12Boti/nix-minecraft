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
  inherit (import ./common.nix inputs) os isAllowed fetchJson;
  inherit (import ./downloaders.nix inputs) downloadLibs downloadAssets;
in
rec {
  # downloads information about a specific version of minecraft
  getMc = { version, sha1 }:
    fetchJson {
      url = "https://launchermeta.mojang.com/v1/packages/${sha1}/${version}.json";
      inherit sha1;
    };

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
        game_directory="$(realpath "$game_directory")"
        mkdir -p "$game_directory"
        cd "$game_directory"
        ${lib.optionalString
        (extraGamedirFiles != null)
        ''
          if [ -d "$game_directory/mods" -a -d "${extraGamedirFiles}/mods" ]; then
            diff -q "$game_directory/mods" "${extraGamedirFiles}/mods" \
              || echo "warning: mods folder already exists, remove it in case of conflicts and try again"
          fi
          echo "copying files to game directory ($game_directory)"
          ${pkgs.rsync}/bin/rsync -rL --ignore-existing --chmod=755 --info=skip2,name ${extraGamedirFiles}/ "$game_directory"
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
        exec env \
          LD_LIBRARY_PATH="$out/natives" \
          ${jre}/bin/java \
          -Djava.library.path="$out/natives" \
          -classpath '${classpath}' \
          '${pkg.mainClass}' \
          ${arguments}
      '';
    in
    pkgs.stdenvNoCC.mkDerivation
      {
        pname = "minecraft";
        version = pkg.id;

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
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
        '';

        doCheck = false;
        doInstallCheck = doCheck;
        installCheckPhase = ''
          echo running checks
          ${pkgs.xdummy}/bin/xdummy :3 \
            -ac -nolisten unix +extension GLX +xinerama +extension RANDR +extension RENDER &
          XPID=$!
          sleep 1
          echo running minecraft
          export DISPLAY=:3
          $out/bin/minecraft NixDude ./gamedir &
          MCPID=$!
          # wait until window visible
          timeout 5s ${pkgs.xdotool}/bin/xdotool search --sync --onlyvisible --pid $MCPID
          ${pkgs.xdotool}/bin/xdotool windowclose
          wait $MCPID
          kill $XPID
        '';
      };

  minecraft =
    { version
    , sha1 # use `getMcHash <version>`
    , extraGamedirFiles ? null
    }:
    minecraftFromPkg {
      pkg = getMc { inherit version sha1; };
      inherit extraGamedirFiles;
    };
}
