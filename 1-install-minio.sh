SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

source ./config

# Install Minio

kubectl create namespace $MINIO_NAMESPACE
cat << EOF | helm install -n $MINIO_NAMESPACE local oci://registry-1.docker.io/bitnamicharts/minio --wait -f -
image:
  debug: true
extraEnvVars:
  - name: MINIO_LOG_LEVEL
    value: DEBUG
EOF

# Configure Minio

export MINIO_USER=$(kubectl get secret --namespace $MINIO_NAMESPACE local-minio -o jsonpath="{.data.root-user}" | base64 -d)
export MINIO_PASSWORD=$(kubectl get secret --namespace $MINIO_NAMESPACE local-minio -o jsonpath="{.data.root-password}" | base64 -d)

cat << EOF > minio-creds
access=${MINIO_USER}
secret=${MINIO_PASSWORD}
EOF

export MINIO_POD=$(kubectl get pods -n $MINIO_NAMESPACE | egrep -v 'console|NAME' | awk '{print $1}')

kubectl exec -n ${MINIO_NAMESPACE} ${MINIO_POD} -- mc alias set local http://local-minio.$MINIO_NAMESPACE.svc.cluster.local:9000 ${MINIO_USER} ${MINIO_PASSWORD}
kubectl exec -n ${MINIO_NAMESPACE} ${MINIO_POD} -- mc mb local/redpanda
kubectl exec -n ${MINIO_NAMESPACE} ${MINIO_POD} -- mc anonymous set public local/redpanda

export MINIO_ENDPOINT=local-minio.$MINIO_NAMESPACE.svc.cluster.local:9000

popd 2> /dev/null




