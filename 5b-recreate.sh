SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config

# Delete
echo "Deleting transform and local primary topic:"
rpk transform delete lvc --no-confirm
rpk topic delete primary
echo
sleep 5

# Create primary topic, that only stores data locally - this should compact more aggressively, so will be faster to read on a full reload
echo "Recreating primary topic:"
rpk topic create primary -p1 --topic-config=redpanda.remote.read=false --topic-config=redpanda.remote.write=false --topic-config=cleanup.policy=compact

# Make compaction more aggressive for demo
rpk topic alter-config primary --set min.cleanable.dirty.ratio=0.01
rpk topic alter-config primary --set max.compaction.lag.ms=1000
rpk topic alter-config primary --set segment.ms=1000
echo
sleep 5

echo "Demoing the empty primary topic:"
rpk topic consume primary --offset :end | jq -c
echo
sleep 5

# Deploy reversing copy (restore) from backup / secondary
echo "Deploying restore transform:"
pushd lvc
rpk transform build
rpk transform deploy -i secondary -o primary --from-offset +0
popd
echo
sleep 5

echo "Wait until the metrics show no more data"
rpk transform delete lvc --no-confirm

# Redeploy transform
echo "Redeploying normal ops backup transform"
pushd lvc
rpk transform build
rpk transform deploy -i primary -o secondary
popd
echo
sleep 5

# Done
echo "Demoing the repopulated primary topic:"
rpk topic consume primary --offset :end | jq -c
echo
sleep 5

# Back to normal
echo "Writing 2 updates:"
echo "a,3" | rpk topic produce primary -f "%k,%v\n"
echo "c,1" | rpk topic produce primary -f "%k,%v\n"
echo
sleep 5

echo "Consume:"
rpk topic consume primary --offset :end | jq -c
echo
sleep 5

echo "Consuming the backup topic:"
rpk topic consume secondary --offset :end | jq -c
echo

popd 2> /dev/null