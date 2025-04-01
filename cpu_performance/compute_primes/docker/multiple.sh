#!/bin/bash

INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)
sudo chown -R $USER:$USER .

SYSBENCH_SCRIPT="sysbench_single.sh"
TOTAL_LOGFILE="./start_end_per_instance.log"
> "$TOTAL_LOGFILE"

# Reset Docker environment back to the local system Docker daemon
eval $(minikube docker-env --unset)

# Set Docker timeout to 5 minutes
export COMPOSE_HTTP_TIMEOUT=300

# 1. Copy sysbench_single.sh from parent directory to current directory
cp ../${SYSBENCH_SCRIPT} .

# 2. Run sysbench with X number of docker instances and log the execution time for each of the instance.
# Loop through each instance count
for INSTANCE_COUNT_ARG in "${INSTANCE_COUNTS[@]}"; do

    # Clear logfile if exists
    LOGFILE="${INSTANCE_COUNT_ARG}_instance.log"
    > "$LOGFILE"

    # Record start time
    START_EPOCH=$(date +%s)

    # Run multiple containers using compose.
    INSTANCE_COUNT=${INSTANCE_COUNT_ARG} docker compose up --build --scale sysbench=${INSTANCE_COUNT_ARG}
done

# 3. Clean up.
rm ./${SYSBENCH_SCRIPT}
rm ./log.lock