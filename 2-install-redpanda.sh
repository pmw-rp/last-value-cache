SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config
export MINIO_USER=$(cat minio-creds | grep access | cut -f2 -d'=')
export MINIO_PASSWORD=$(cat minio-creds | grep secret | cut -f2 -d'=')

cat << EOF | helm upgrade --install redpanda redpanda/redpanda \
  --version 25.1.1 \
  --namespace $REDPANDA_NAMESPACE \
  --create-namespace \
  --wait \
  -f -
image:
  repository: docker.redpanda.com/redpandadata/redpanda
  tag: v25.2.2
external:
  enabled: true
  service:
    enabled: false
  addresses:
  - localhost
listeners:
  kafka:
    external:
      default:
        enabled: true
        port: 9094
        advertisedPorts:
        - 9094
statefulset:
  replicas: 1
config:
  cluster:
    default_topic_replications: 1
storage:
  tiered:
    config:
      cloud_storage_enabled: true
      cloud_storage_bucket: redpanda
      cloud_storage_api_endpoint: local-minio.$MINIO_NAMESPACE.svc.cluster.local
      cloud_storage_api_endpoint_port: 9000
      cloud_storage_disable_tls: true
      cloud_storage_region: local
      cloud_storage_access_key: ${MINIO_USER}
      cloud_storage_secret_key: ${MINIO_PASSWORD}
      cloud_storage_segment_max_upload_interval_sec: 30
      cloud_storage_url_style: path
      cloud_storage_enable_remote_write: true
      cloud_storage_enable_remote_read: true
      data_transforms_enabled: true
      log_compaction_interval_ms: 1000
      log_segment_ms_min: 1000
tls:
  enabled: false
auth:
  sasl:
    enabled: false
EOF

if [ "$(kubectl get nodes | tail -1 | awk '{print $1}')" = "orbstack" ]; then
    rpk profile create rp-bcced7fb -s brokers=redpanda.${REDPANDA_NAMESPACE}.svc.cluster.local:9093 -s admin.hosts=redpanda.${REDPANDA_NAMESPACE}.svc.cluster.local:9644 || rpk profile use rp-bcced7fb
else
    kubectl port-forward pod/redpanda-0 -n $REDPANDA_NAMESPACE 9094 9644 &
    echo $! > port-forward.pid
    rpk profile create local-bcced7fb -s brokers=localhost:9094 -s admin.hosts=localhost:9644 || rpk profile use local-bcced7fb
fi

popd 2> /dev/null