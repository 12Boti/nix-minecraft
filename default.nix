{ pkgs ? import <nixpkgs> {}
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
      else abort "unsupported OS";

  fetchJson = { url, sha1 ? "", sha256 ? "", hash ? "" }:
    let
      file = pkgs.fetchurl {
        inherit url sha1 sha256 hash;
      };
      json = builtins.readFile file;
    in
      builtins.fromJSON json;

  metaUrl = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json";
  manifest = fetchJson {
    url = metaUrl;
    hash = "sha256-wB4w2lLARKgDWzqzD8xsgjmZpAddoKVYPNANXdPziwU=";
  };

  # downloads information about a specific version of minecraft
  getMc = { version }:
    let
      part = lib.lists.findFirst
        (x: x.id == version)
        (abort "couldn't find version '${version}'")
        manifest.versions;
    in
      fetchJson {
        inherit (part) url sha1;
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
                pkgs.fetchurl {
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
                pkgs.runCommand "unpack-zip" {} ''
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
      pkgs.runCommand "symlink-assets" {} script;

  minecraftFromPkg =
    { pkg, extraJars ? [] }:
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
              "${pkgs.xorg.libXxf86vm}/lib"
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
                      mkdir -p $out/$(dirname ${x.passthru.path})
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
            pkgs.runCommand "symlink-jars" {} script;

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
        runner = pkgs.writeText "minecraft-runner" ''
          #! ${pkgs.bash}/bin/bash
          out='%OUT%'
          LD_LIBRARY_PATH="$out/natives"
          auth_player_name='NixDude'
          version_name='${pkg.id}'
          game_directory='./gamedir'
          assets_root="$out/assets"
          assets_index_name='${pkg.assetIndex.id}'
          auth_uuid='1234'
          auth_access_token='REPLACEME'
          user_type='mojang'
          version_type='${pkg.type}'
          exec ${jre}/bin/java \
            -Djava.library.path="$out/natives" \
            -classpath '${classpath}' \
            '${pkg.mainClass}' \
            ${arguments}
        '';
      in
        pkgs.runCommand "minecraft-env" {} ''
          mkdir -p $out
          ln -s ${javaLibsDir} $out/libraries
          ln -s ${nativeLibsDir} $out/natives
          ln -s ${assets} $out/assets
          mkdir -p $out/bin
          sed "s|%OUT%|$out|" ${runner} > $out/bin/minecraft
          chmod +x $out/bin/minecraft
        '';

  minecraft =
    { version }:
      minecraftFromPkg { pkg = (getMc { inherit version; }); };

  minecraftForge =
    { installer }:
      let
        forgeJar = pkgs.runCommand "forge.jar" {} ''
          ${pkgs.jre}/bin/java -jar ${installer} --extract
          cp *.jar $out
        '';
        pkg =
          let
            versionJsonFile = pkgs.runCommand "forge-version.json" {} ''
              ${pkgs.unzip}/bin/unzip -p ${installer} version.json > $out
            '';
            forge = builtins.fromJSON (builtins.readFile versionJsonFile);
            mc = getMc { version = forge.inheritsFrom; };
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
        minecraftFromPkg { inherit pkg; extraJars = [ forgeJar ]; };
in
  # forge
minecraftForge {
  installer = (import ./nix/sources.nix).forge;
}
