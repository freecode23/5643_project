#!/bin/bash

INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)

minikube start

# Point shell to Minikube's Docker daemon
eval $(minikube docker-env)

# Build image inside Minikube
docker build -t sysbench-container:latest .

# Get absolute path to current directory
LOCAL_PATH=$(pwd)
MOUNT_PATH="/host-mnt/sysbench"

# Start the Minikube mount in the background
minikube mount "$LOCAL_PATH:$MOUNT_PATH" --uid 0 --gid 0 &
MOUNT_PID=$!

# Loop through different instance counts and create Jobs dynamically
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    JOB_NAME="sysbench-job-${INSTANCE_COUNT}"
    echo "Launching Kubernetes Job: ${JOB_NAME} with ${INSTANCE_COUNT} instances"

    # Delete the job if it already exists (suppress errors if not found)
    kubectl delete job "${JOB_NAME}" --ignore-not-found=true

    # Create a temporary YAML file with the updated instance count
    cp sysbench-job.yaml temp-job.yaml
    sed -i "s/sysbench-job/sysbench-job-${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/completions: 1/completions: ${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/parallelism: 1/parallelism: ${INSTANCE_COUNT}/g" temp-job.yaml
    sed -i "s/value: \"1\"/value: \"${INSTANCE_COUNT}\"/g" temp-job.yaml

    # Apply the job
    kubectl apply -f temp-job.yaml

    # Wait for the job to finish before moving on
    echo "Waiting for job ${JOB_NAME} to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/${JOB_NAME}
done

# Cleanup
kill $MOUNT_PID
kubectl delete jobs --all
kubectl delete pods --all
minikube stop
minikube delete
rm temp-job.yaml
