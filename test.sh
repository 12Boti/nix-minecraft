#! /usr/bin/env nix-shell
#! nix-shell -i bash -p parallel
set -eu
rm -rf "test"
mkdir "test"
cd "test"
nix-build ../ci.nix
ls | parallel -j 2 bash ../test-one.sh
