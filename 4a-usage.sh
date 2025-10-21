SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config

echo "Writing 3 messages:"
echo "a,1" | rpk topic produce source -f "%k,%v\n"
echo "b,1" | rpk topic produce source -f "%k,%v\n"
echo "c,1" | rpk topic produce source -f "%k,%v\n"
echo
sleep 5

echo "Consume:"
rpk topic consume destination --offset :end | jq -c
echo
sleep 5

echo "Writing 2 updates:"
echo "b,2" | rpk topic produce source -f "%k,%v\n"
echo "c,2" | rpk topic produce source -f "%k,%v\n"
echo
sleep 5

echo "Consume:"
rpk topic consume destination --offset :end | jq -c
echo
sleep 5

echo "Writing 1 update:"
echo "c,3" | rpk topic produce source -f "%k,%v\n"
echo
sleep 5

echo "Consume:"
rpk topic consume destination --offset :end | jq -c
echo
sleep 5

echo "Consuming the original source topic:"
rpk topic consume source --offset :end | jq -c
echo

popd 2> /dev/null