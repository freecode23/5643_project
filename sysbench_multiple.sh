#!/bin/bash

# Script to run sysbench_single.sh with multiple instance counts and store results in separate log files

# Define instance counts to test
INSTANCE_COUNTS=(1 2 32)
NUM_RUNS=10  # Number of times to run each test

# Ensure sysbench_single.sh is executable
chmod +x sysbench_single.sh

echo "Running Sysbench CPU benchmark for multiple instance counts..."

# Loop through each instance count
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    LOGFILE="sysbench_cpu_${INSTANCE_COUNT}_instance.log"
    echo "Running Sysbench with ${INSTANCE_COUNT} instance(s)... Log: $LOGFILE"
    
    # Execute sysbench_single.sh with instance count and log file as arguments
    ./sysbench_single.sh --instances $INSTANCE_COUNT --logfile "$LOGFILE"

done

# Print completion message
echo "Test completed. Logs saved in sysbench_cpu_*_instance.log files."
