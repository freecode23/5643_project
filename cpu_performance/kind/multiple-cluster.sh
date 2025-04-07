#!/bin/bash
# -----------------------------------------
# This script should be executed inside kind directory.
# -----------------------------------------
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)
INSTANCE_COUNTS=(128)


sudo chown -R $USER:$USER .

# -----------------------------------------
# 1. Copy required files to current directory
# -----------------------------------------
SYSBENCH_SCRIPT="./sysbench_single.sh"
DOCKERFILE="Dockerfile"
TOTAL_LOGFILE="./start_end_per_instance.log"
> "$TOTAL_LOGFILE"

cp ../docker/${DOCKERFILE} .

# -----------------------------------------
# 2. Set up Kind cluster
# -----------------------------------------
kind delete cluster  # Optional: cleanup before recreate
kind create cluster --config kind-config.yaml
docker build -t sysbench-container:latest .
kind load docker-image sysbench-container:latest

# -----------------------------------------
# 3. Create Kubernetes jobs for each instance count
# -----------------------------------------
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    JOB_NAME="sysbench-job-${INSTANCE_COUNT}"
    echo "Launching Kubernetes Job: ${JOB_NAME} with ${INSTANCE_COUNT} instances"

    # 3.0 Clear log file if it exists
    LOGFILE="./${INSTANCE_COUNT}_cluster.log"
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

    # 3.4 Record start time (Measure just job execution time)
    START_EPOCH=$(date +%s)

    # 3.5 Wait for the job to finish before moving to next INSTANCE_COUNT.
    echo "Waiting for job ${JOB_NAME} to complete..."
    kubectl wait --for=condition=complete --timeout=3600s job/${JOB_NAME}

    # 3.6. Record end time
    END_EPOCH=$(date +%s)
    DURATION=$((END_EPOCH - START_EPOCH))
    kubectl delete job "${JOB_NAME}" --ignore-not-found=true

    # 3.7. Log as csv
    echo "${INSTANCE_COUNT},${DURATION}" >> "$TOTAL_LOGFILE"
done

# -----------------------------------------
# 4. Clean up
# -----------------------------------------
kubectl delete jobs --all
kubectl delete pods --all
rm temp-job.yaml
rm ./${DOCKERFILE}
rm ./log.lock
