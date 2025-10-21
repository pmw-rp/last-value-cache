SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config

# Delete
echo "Deleting transform and local destination topic:"
rpk transform delete lvc --no-confirm
rpk topic delete destination
echo
sleep 5

# Create destination topic, that only stores data locally - this should compact more aggressively, so will be faster to read on a full reload
echo "Recreating destination topic:"
rpk topic create destination -p1 --topic-config=redpanda.remote.read=false --topic-config=redpanda.remote.write=false --topic-config=cleanup.policy=compact

# Make compaction more aggressive for demo
rpk topic alter-config destination --set min.cleanable.dirty.ratio=0.01
rpk topic alter-config destination --set max.compaction.lag.ms=1000
rpk topic alter-config destination --set segment.ms=1000
echo
sleep 5

echo "Demoing the empty destination topic:"
rpk topic consume destination --offset :end | jq -c
echo
sleep 5

# Redeploy transform
echo "Redeploying transform and rebuilding local value cache:"
pushd lvc
rpk transform build
rpk transform deploy -i source -o destination --from-offset +0
popd
echo
sleep 5

# Done
echo "Demoing the populated destination topic:"
rpk topic consume destination --offset :end | jq -c
echo
sleep 5

popd 2> /dev/null