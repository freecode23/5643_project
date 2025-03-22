#!/bin/bash
# -----------------------------------------
# This script should be executed inside k8s directory.
# -----------------------------------------
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)
INSTANCE_COUNTS=(128)

# -----------------------------------------
# 1. Copy required files to k8s directory
# -----------------------------------------
SYSBENCH_SCRIPT="sysbench_single.sh"
DOCKERFILE="Dockerfile"
cp ../${SYSBENCH_SCRIPT} .
cp ../docker/${DOCKERFILE} .

# -----------------------------------------
# 2. Minikube set up.
# -----------------------------------------
minikube start --memory=6656 --cpus=4

# 2.1 Point shell to Minikube's Docker daemon
eval $(minikube docker-env)

# 2.2 Build image inside Minikube
docker build -t sysbench-container:latest .

# 2.3 Get absolute path and mount path.
LOCAL_PATH=$(pwd)
MOUNT_PATH="/host-mnt/sysbench"

# 2.4 Start the Minikube mount in the background
minikube mount "$LOCAL_PATH:$MOUNT_PATH" --uid 0 --gid 0 &
MOUNT_PID=$!

# -----------------------------------------
# 3. Create kubernetes job with x number of instances or pod.
# -----------------------------------------

# Loop through different instance counts and create Jobs dynamically
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    JOB_NAME="sysbench-job-${INSTANCE_COUNT}"
    echo "Launching Kubernetes Job: ${JOB_NAME} with ${INSTANCE_COUNT} instances"

    # 3.0 Clear log file if it exists
    LOGFILE="./${INSTANCE_COUNT}_instance.log"
    > "$LOGFILE"

    # 3.1 Delete the job if it already exists (suppress errors if not found)
    kubectl delete job "${JOB_NAME}" --ignore-not-found=true

    # 3.2 Create a temporary YAML file with the updated instance count
    cp sysbench-job.yaml temp-job.yaml
    sed -i "s/sysbench-job/sysbench-job-${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/completions: 1/completions: ${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/parallelism: 1/parallelism: ${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/value: \"1\"/value: \"${INSTANCE_COUNT}\"/g" temp-job.yaml

    # 3.3 Apply the job
    kubectl apply -f temp-job.yaml

    # 3.4 Wait for the job to finish before moving to next INSTANCE_COUNT.
    echo "Waiting for job ${JOB_NAME} to complete..."
    kubectl wait --for=condition=complete --timeout=3600s job/${JOB_NAME}
done


# -----------------------------------------
# 4. Clean up
# -----------------------------------------
kill $MOUNT_PID
kubectl delete jobs --all
kubectl delete pods --all
minikube stop
minikube delete
rm temp-job.yaml
rm ./${SYSBENCH_SCRIPT}
rm ./${DOCKERFILE}

