SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config

# Create primary topic, that only stores data locally - this should compact more aggressively, so will be faster to read on a full reload
rpk topic create primary -p1 --topic-config=redpanda.remote.read=false --topic-config=redpanda.remote.write=false --topic-config=cleanup.policy=compact

# Make compaction more aggressive for demo
rpk topic alter-config primary --set min.cleanable.dirty.ratio=0.01
rpk topic alter-config primary --set max.compaction.lag.ms=1000
rpk topic alter-config primary --set segment.ms=1000

# Create secondary topic, that uses tiered storage - this is our backup
rpk topic create secondary -p1 --topic-config=redpanda.remote.read=true --topic-config=redpanda.remote.write=true --topic-config=cleanup.policy=compact

# Create, build and deploy the WASM transform that will copy data between the source and destination topics
rpk transform init --language=tinygo --name lvc --install-deps lvc
pushd lvc
rpk transform build
rpk transform deploy -i primary -o secondary
popd

popd 2> /dev/null