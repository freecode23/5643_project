#!/bin/bash

SYSBENCH_SCRIPT="sysbench_single.sh"
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256 512)

# 1. Copy sysbench_single.sh from parent directory to current directory
cp ../${SYSBENCH_SCRIPT} .

# 2. Run sysbench with X number of docker instances and log the execution time for each of the instance.
# Loop through each instance count
for INSTANCE_COUNT_ARG in "${INSTANCE_COUNTS[@]}"; do
    INSTANCE_COUNT=${INSTANCE_COUNT_ARG} docker-compose up --build --scale sysbench=${INSTANCE_COUNT_ARG}
done

# 3. Delete sysbench_single.sh in the current directory.
rm ./${SYSBENCH_SCRIPT}