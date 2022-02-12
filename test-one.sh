set -eu
mkdir $1.dir
cd $1.dir
../$1/bin/minecraft >& ../$1.log &
PID=$!
sleep 30
if kill -0 $PID
then
    kill $PID
    wait $PID || true
    cd ..
    rm -r $1.dir
    rm $1.log
    rm $1
else
    echo "TEST CASE $1 FAILED!"
    echo "$1" >> ../failed.txt
fi
