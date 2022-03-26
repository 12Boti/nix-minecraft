set -eu
trap 'echo "TEST CASE $1 FAILED!"; echo "$1" >> ../failed.txt' EXIT
mkdir $1.dir
cd $1.dir
nix build .\#checks.x86_64-linux.$1 &>> ../$1.log
./result/bin/minecraft &>> ../$1.log &
PID=$!
sleep 30
if kill -0 $PID
then
    kill $PID
    wait $PID || true
    cd ..
    rm -r $1.dir
    rm $1.log
    trap "" EXIT
fi
