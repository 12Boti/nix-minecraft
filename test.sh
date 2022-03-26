#! /usr/bin/env nix-shell
#! nix-shell -i bash -p parallel
set -eu
rm -rf "test"
mkdir "test"
cd "test"
nix eval .\#checks.x86_64-linux --apply builtins.attrNames --json | jq -r .[] \
    | parallel bash ../test-one.sh
