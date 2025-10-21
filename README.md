# Redpanda Last Value Cache Demo!

Welcome to the Redpanda Last Value Cache demo. This demo will install and configure the following components on K8s:

- Minio (local S3 storage)
- Redpanda (our beloved streaming system!)

# Setup

### Configure Namespaces

First, configure the namespaces you want to install to by editing [`config`](config):

```zsh
vim config
```

```zsh
export MINIO_NAMESPACE=minio
export REDPANDA_NAMESPACE=redpanda
```

### Run the setup scripts

To install Minio and Redpanda, run the setup scripts:

```bash
# Be sure to use source when installing Minio, since the script publishes environment
# variables used when installing Redpanda

# Install Minio
source ./1-install-minio.sh

# Install Redpanda
./2-install-redpanda.sh
```

## Demo

The demo is built using three scripts:

- The first script creates the topics required, configures them appropriately, configures the compaction to be
demo-friendly and deploys the transform;
- The second script shows producing to the source topic and consuming from the (highly compacted) destination topic;
- The third script shows how we can recreate the destination topic by redeploying the transform and having it process
all the existing data 

```bash
./3-create-topics.sh
./4-usage.sh
./5-recreate.sh
```