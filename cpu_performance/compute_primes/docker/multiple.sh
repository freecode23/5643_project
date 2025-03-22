#!/bin/bash

SYSBENCH_SCRIPT="sysbench_single.sh"
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)

# Reset Docker environment back to the local system Docker daemon
eval $(minikube docker-env --unset)
    echo -e "\n\nRunning Sysbench with ${INSTANCE_COUNT} concurrent instance(s)... Logfile: $LOGFILE"

# Set Docker timeout to 5 minutes
export COMPOSE_HTTP_TIMEOUT=300

# 1. Copy sysbench_single.sh from parent directory to current directory
cp ../${SYSBENCH_SCRIPT} .

# 2. Run sysbench with X number of docker instances and log the execution time for each of the instance.
# Loop through each instance count
for INSTANCE_COUNT_ARG in "${INSTANCE_COUNTS[@]}"; do

    # Clear logfile if exists
    LOGFILE="./${INSTANCE_COUNT}_instance.log"
    > "$LOGFILE"

    # Run multiple containers using compose.
    INSTANCE_COUNT=${INSTANCE_COUNT_ARG} docker compose up --build --scale sysbench=${INSTANCE_COUNT_ARG}
done

# 3. Delete sysbench_single.sh in the current directory.
rm ./${SYSBENCH_SCRIPT}