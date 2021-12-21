{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    username = mkOption {
      description = ''
        Your in-game username.
        Can be overwritten with the "MINECRAFT_USERNAME" environment variable.
      '';
      example = "NixDude";
      type = types.nonEmptyStr;
    };

    gamedir = mkOption {
      description = ''
        The directory where worlds, mods and other files are stored.
        If it's not an absolute path, it's relative to the working directory
        where you run minecraft.
        Can be overwritten with the "MINECRAFT_GAMEDIR" environment variable.
      '';
      example = "./gamedir";
      type = types.nonEmptyStr;
    };

    extraGamedirFiles = mkOption {
      description = "Extra files to symlink into the game directory.";
      default = [ ];
      type = types.listOf (types.submodule {
        options = {
          path = mkOption {
            description = "Where to link the file, relative to the game directory.";
            example = "config/something.cfg";
            type = types.nonEmptyStr;
          };
          source = mkOption {
            description = "Path to the file to be linked.";
            type = types.path;
          };
        };
      });
    };

    cleanFiles = mkOption {
      description = ''
        Files and directories relative to the game directory to delete on every
        startup. Defaults to the "mods" folder.
      '';
      example = ''
        <pre><code>
        [ "config" "mods" "resourcepacks" "options.txt" ]
        </code></pre>
      '';
      default = [ "mods" ];
      type = types.listOf types.nonEmptyStr;
    };

    mods.manual = mkOption {
      example = ''
        <pre><code>
        map pkgs.fetchurl [
          # Extended Hotbar
          {
            url = "https://github.com/DenWav/ExtendedHotbar/releases/download/1.2.0/mod-extendedhotbar-1.2.0-mc1.12.2.litemod";
            hash = "sha256-CyB7jypxXq41wAfb/t1RCsxaS8uZZjAl/h531osq0Fc=";
          }
        ]
        </code></pre>
      '';
      default = [ ];
      type = types.listOf types.path;
      description = ''
        A list of .jar files to use as mods.
      '';
    };

    runners.client = mkOption {
      type = types.package;
      internal = true;
    };
  };

  config.extraGamedirFiles = map
    (m: { path = "mods/${lib.getName m}"; source = m; })
    config.mods.manual;

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
      }.${toString config.internal.javaVersion};

      extraGamedir =
        if config.extraGamedirFiles == [ ]
        then null
        else
          let scripts = map
            ({ path, source }: ''
              mkdir -p "$(dirname "$out/${path}")"
              ln -s "${source}" "$out/${path}"
            '')
            config.extraGamedirFiles;
          in
          pkgs.runCommand "symlink-gamedir-files" { }
            (lib.concatStringsSep "\n" scripts);

      runner = pkgs.writeShellScript "minecraft-runner" ''
        set -o errexit
        set -o pipefail
        out='%OUT%'
        auth_player_name="''${MINECRAFT_USERNAME:-${config.username}}"
        version_name='${config.minecraft.version}'
        game_directory="''${MINECRAFT_GAMEDIR:-${config.gamedir}}"
        game_directory="$(realpath "$game_directory")"
        mkdir -p "$game_directory"
        cd "$game_directory"
        ${lib.optionalString (config.cleanFiles != [])
        ''
          rm -rfv ${lib.escapeShellArgs config.cleanFiles}
        ''}
        ${lib.optionalString (extraGamedir != null)
        ''
          if [ -d "$game_directory/mods" -a -d "$out/gamedir/mods" ]; then
            diff -q "$game_directory/mods" "$out/gamedir/mods" \
              || echo "warning: mods folder already exists, remove it in case of conflicts and try again"
          fi
          echo "copying files to game directory ($game_directory)"
          ${pkgs.rsync}/bin/rsync -rL --ignore-existing --chmod=755 --info=skip2,name $out/gamedir/ "$game_directory"
        ''}
        assets_root="$out/assets"
        assets_index_name='${config.internal.assets.id}'
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
          '${config.internal.mainClass}' \
          ${lib.concatMapStringsSep " " (x: ''"${x}"'') config.internal.arguments}
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
          (extraGamedir != null)
          "ln -s ${extraGamedir} $out/gamedir"}
          echo creating runner script
          mkdir -p $out/bin
          sed "s|%OUT%|$out|" ${runner} > $out/bin/minecraft
          chmod +x $out/bin/minecraft
        '';
      };
}
