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

{ pkgs
, lib
, name
, enabled
, nativeBuildInputs ? [ ]
, hash
, jsonnetFile
, scriptBefore ? "" # should produce an `orig.json` file
, scriptAfter ? ""
}:
let
  inherit (pkgs) runCommand jsonnet jq curl cacert;
  inherit (lib) mkOverride importJSON;

  drv = runCommand name
    {
      nativeBuildInputs = [ jsonnet jq curl ] ++ nativeBuildInputs;
      SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      outputHash = hash;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    }
    ''
      mkdir -p $out
      JSONNET_ARGS=""

      ${scriptBefore}

      jsonnet -J ${./jsonnet} -m $out \
        --tla-str-file orig_str=orig.json \
        $JSONNET_ARGS \
        ${jsonnetFile}
        
      jq -r '.[] | .url + " " + .path' < $out/downloads.json | \
      while read url path
      do
        curl -L -o "$out/$path" "$url"
      done

      ${scriptAfter}

      rm $out/downloads.json
    '';
  module = importJSON "${drv}/package.json";
in
{
  inherit drv;
  module =
    lib.optionalAttrs enabled (
      (removeAttrs module [ "overrideArguments" ]) // {
        minecraftArgs =
          if module.overrideArguments
          then mkOverride 90 module.minecraftArgs
          else module.minecraftArgs;
        mainClass = mkOverride 90 module.mainClass;
        libraries = map
          (l:
            if l ? path
            then l // { path = "${drv}/${l.path}"; }
            else l
          )
          module.libraries;
      }
    );
}
