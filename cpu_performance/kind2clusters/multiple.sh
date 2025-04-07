#!/bin/bash
# -----------------------------------------
# This script should be executed inside kind directory.
# -----------------------------------------
INSTANCE_COUNTS=(128)

sudo chown -R $USER:$USER .

# -----------------------------------------
# 1. Copy required files to current directory
# -----------------------------------------
SYSBENCH_SCRIPT="sysbench_single.sh"
DOCKERFILE="Dockerfile"
TOTAL_LOGFILE="./start_end_per_instance.log"
> "$TOTAL_LOGFILE"

cp ../${SYSBENCH_SCRIPT} .
cp ../docker/${DOCKERFILE} .

# -----------------------------------------
# 2. Set up Kind cluster
# -----------------------------------------
kind delete cluster --name kind-cluster2

echo "Creating kind-cluster2..."
kind create cluster --name kind-cluster2 --config kind-config.yaml

# Wait for context to be ready
echo "Waiting for cluster context..."
until kubectl config get-contexts | grep -q kind-kind-cluster2; do
  sleep 2
done

# Set correct API server address to avoid TLS errors
kubectl config set-cluster kind-kind-cluster2 --server=https://127.0.0.1:6445
kubectl config use-context kind-kind-cluster2

# Wait for nodes to be ready
echo "Waiting for all nodes to be Ready..."
until kubectl get nodes | grep -E " Ready "; do
  sleep 2
done

# -----------------------------------------
# 3. Build + Load Docker image
# -----------------------------------------
docker build -t sysbench-container:latest .
kind load docker-image sysbench-container:latest --name kind-cluster2

# -----------------------------------------
# 4. Create Kubernetes jobs
# -----------------------------------------
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    JOB_NAME="sysbench-job-${INSTANCE_COUNT}"
    echo "Launching Kubernetes Job: ${JOB_NAME} with ${INSTANCE_COUNT} instances"

    LOGFILE="./${INSTANCE_COUNT}_instance.log"
    > "$LOGFILE"

    kubectl delete job "${JOB_NAME}" --ignore-not-found=true

    cp sysbench-job.yaml temp-job.yaml
    sed -i "s/sysbench-job/sysbench-job-${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/completions: 1/completions: ${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/parallelism: 1/parallelism: ${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/value: \"1\"/value: \"${INSTANCE_COUNT}\"/g" temp-job.yaml

    kubectl apply -f temp-job.yaml

    START_EPOCH=$(date +%s)
    echo "Waiting for job ${JOB_NAME} to complete..."
    kubectl wait --for=condition=complete --timeout=3600s job/${JOB_NAME}

    END_EPOCH=$(date +%s)
    DURATION=$((END_EPOCH - START_EPOCH))

    echo "${INSTANCE_COUNT},${DURATION}" >> "$TOTAL_LOGFILE"

    kubectl delete job "${JOB_NAME}" --ignore-not-found=true
done

# -----------------------------------------
# 5. Clean up
# -----------------------------------------
kubectl delete jobs --all
kubectl delete pods --all
rm temp-job.yaml
rm ./${SYSBENCH_SCRIPT}
rm ./${DOCKERFILE}
rm ./log.lock
