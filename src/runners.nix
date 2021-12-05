{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    arguments = mkOption {
      type = types.listOf types.str;
    };

    javaVersion = mkOption {
      type = types.int;
    };

    mainClass = mkOption {
      type = types.nonEmptyStr;
    };

    runners.client = mkOption {
      type = types.package;
    };
  };

  config.runners.client =
    let
      nativeLibsDir = pkgs.symlinkJoin {
        name = "minecraft-natives";
        paths =
          config.downloaded.natives
          ++ [
            "${pkgs.libpulseaudio}/lib"
            "${pkgs.xlibs.libXxf86vm}/lib"
          ];
      };

      classpath = lib.concatStringsSep ":" config.downloaded.jars;

      jre = {
        "8" = pkgs.jre8;
        "16" = pkgs.jre;
        "17" = pkgs.jre;
      }.${toString config.javaVersion};

      extraGamedirFiles = null;

      runner = pkgs.writeShellScript "minecraft-runner" ''
        out='%OUT%'
        usage="Usage: $0 <username> [<gamedir>]"
        test $# -eq 0 && echo $usage && exit 1
        test "$1" = "-h" -o "$1" = "--help" && echo $usage && exit 1
        auth_player_name="$1"
        version_name='${config.minecraft.version}'
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
        assets_index_name='${config.assets.id}'
        auth_uuid='1234'
        auth_access_token='REPLACEME'
        user_type='mojang'
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
          '${config.mainClass}' \
          ${lib.concatMapStringsSep " " (x: ''"${x}"'') config.arguments}
      '';
    in
    pkgs.stdenvNoCC.mkDerivation
      {
        pname = "minecraft";
        version = config.minecraft.version;

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          echo setting up environment
          mkdir -p $out
          ln -s ${nativeLibsDir} $out/natives
          ln -s ${config.downloaded.assets} $out/assets
          ${lib.optionalString
          (extraGamedirFiles != null)
          "ln -s ${extraGamedirFiles} $out/gamedir"}
          echo creating runner script
          mkdir -p $out/bin
          sed "s|%OUT%|$out|" ${runner} > $out/bin/minecraft
          chmod +x $out/bin/minecraft
        '';
      };
}
