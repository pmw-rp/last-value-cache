SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config

# Create source topic, that uses tiered storage - this is our "source of truth"
rpk topic create source -p1 --topic-config=redpanda.remote.read=true --topic-config=redpanda.remote.write=true --topic-config=cleanup.policy=compact

# Create destination topic, that only stores data locally - this should compact more aggressively, so will be faster to read on a full reload
rpk topic create destination -p1 --topic-config=redpanda.remote.read=false --topic-config=redpanda.remote.write=false --topic-config=cleanup.policy=compact

# Make compaction more aggressive for demo
rpk topic alter-config destination --set min.cleanable.dirty.ratio=0.01
rpk topic alter-config destination --set max.compaction.lag.ms=1000
rpk topic alter-config destination --set segment.ms=1000

# Create, build and deploy the WASM transform that will copy data between the source and destination topics
rpk transform init --language=tinygo --name lvc --install-deps lvc
pushd lvc
rpk transform build
rpk transform deploy -i source -o destination
popd

popd 2> /dev/null