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

  metaUrl = "https://meta.multimc.org/v1";
  packageManifest = fetchJson {
    url = metaUrl;
    hash = "sha256-R5RpVr67kFJhR1WKTREEWjK/f39asEyBWsWDgmSPcPM=";
  };

  # downloads information about available versions of a package
  getPackageVersions = { uid }:
    let
      packageInfo =
        lib.findSingle
          (p: p.uid == uid)
          (abort "package not found")
          (abort "multiple matching packages")
          packageManifest.packages;
    in
      (
        fetchJson {
          inherit (packageInfo) sha256;
          url = "${metaUrl}/${uid}";
        }
      ).versions;

  # downloads information about a specific version of a package
  getPackage = { uid, version }:
    let
      versions = getPackageVersions { inherit uid; };

      part = lib.lists.findFirst
        (x: x.version == version)
        (abort "couldn't find version '${version}'")
        versions;
    in
      fetchJson {
        inherit (part) sha256;
        url = "${metaUrl}/${uid}/${version}.json";
      };

  # downloads the java and native libraries in the list
  downloadLibs = libs:
    let
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
                x: x ? downloads.artifact && (x ? rules -> isAllowed x.rules)
              )
              libs
          );
      nativeLibs =
        map
          (
            nativeLib:
              let
                classifier = nativeLib.natives.${os};
                zip =
                  pkgs.fetchurl {
                    inherit (nativeLib.downloads.classifiers.${classifier}) url sha1;
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

  # downloads all required libraries for a package and its dependencies
  downloadLibsRecursive = pkg:
    if pkg ? requires then
      let
        libs = downloadLibs (
          pkg.libraries
          ++ lib.optional (pkg ? mainJar) pkg.mainJar
          ++ pkg.mavenFiles or []
        );
        deps =
          map
            (
              r: downloadLibsRecursive (
                getPackage {
                  inherit (r) uid;
                  version = r.suggests or r.equals;
                }
              )
            )
            pkg.requires;
      in
        {
          javaLibs =
            libs.javaLibs
            ++ builtins.concatLists (lib.catAttrs "javaLibs" deps);
          nativeLibs =
            libs.nativeLibs
            ++ builtins.concatLists (lib.catAttrs "nativeLibs" deps);
        }
    else
      # no dependencies, no need for recursion
      downloadLibs pkg.libraries;

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

  minecraft =
    { version
    , forgeMods ? []
    }:
      let
        mcPkg = getPackage { uid = "net.minecraft"; inherit version; };
        pkg =
          if forgeMods == []
          then mcPkg
          else
            let
              versions = getPackageVersions { uid = "net.minecraftforge"; };
              latestVersion =
                lib.lists.findFirst
                  (
                    x: builtins.elem
                      {
                        equals = version;
                        uid = "net.minecraft";
                      }
                      x.requires
                  )
                  (abort "couldn't find forge version for minecraft ${version}")
                  versions;
            in
              getPackage {
                uid = "net.minecraftforge";
                inherit (latestVersion) version;
              };

        assets = downloadAssets mcPkg.assetIndex;

        inherit (downloadLibsRecursive pkg) javaLibs nativeLibs;

        classpath = lib.concatStringsSep ":" javaLibs;
        nativeLibsDir = pkgs.symlinkJoin {
          name = "minecraft-natives";
          paths =
            nativeLibs
            ++ lib.optionals (os == "linux") [
              "${pkgs.libpulseaudio}/lib"
              "${pkgs.xorg.libXxf86vm}/lib"
            ];
        };

        forgeInstaller =
          lib.findFirst
            (x: builtins.match ".*installer\.jar" "${x}" != null)
            null
            javaLibs;

        clientJar =
          lib.findFirst
            (x: builtins.match ".*client\.jar" "${x}" != null)
            (abort "client not found")
            javaLibs;

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
      in
        pkgs.writeScriptBin "minecraft" ''
          LD_LIBRARY_PATH=${nativeLibsDir}
          auth_player_name='NixDude'
          version_name='${pkg.version}'
          game_directory='./gamedir'
          mkdir -p $game_directory
          cp --no-preserve=all -r ${javaLibsDir}/* $game_directory/libraries
          chmod -R +w $game_directory/libraries
          assets_root='${assets}'
          assets_index_name='${mcPkg.assetIndex.id}'
          auth_uuid='1234'
          auth_access_token='REPLACEME'
          user_type='mojang'
          version_type='${mcPkg.type}'
          exec ${pkgs.jre}/bin/java \
            -Djava.library.path=${nativeLibsDir} \
            -Dforgewrapper.librariesDir=$game_directory/libraries \
            -Dforgewrapper.installer=${toString forgeInstaller} \
            -Dforgewrapper.minecraft=${clientJar} \
            -classpath ${classpath} \
            ${pkg.mainClass} \
            ${pkg.minecraftArguments or mcPkg.minecraftArguments} \
            --tweakClass net.minecraftforge.fml.common.launcher.FMLTweaker
        '';
in
minecraft {
  version = "1.16.1";
  forgeMods = [ "asd" ];
}
