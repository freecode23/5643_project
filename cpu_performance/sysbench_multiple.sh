#!/bin/bash

# Define instance counts to test
INSTANCE_COUNTS=(1 32 128)
NUM_RUNS=10  # Number of times to run each test

# Ensure sysbench_single.sh is executable
chmod +x sysbench_single.sh

echo "Running Sysbench CPU benchmark for multiple instance counts..."

# Loop through each instance count
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    LOGFILE="sysbench_cpu_${INSTANCE_COUNT}_instance.log"
    echo -e "\n\nRunning Sysbench with ${INSTANCE_COUNT} concurrent instance(s)... Logfile: $LOGFILE"

    # Clear log file if it exists
    > "$LOGFILE"
    
    # Start multiple sysbench_single.sh instances in parallel
    for ((i=1; i<=INSTANCE_COUNT; i++)); do
        ./sysbench_single.sh "$LOGFILE" "$i" &  # Pass instance ID
    done

    # Wait for all instances of the current test to finish before moving to the next
    wait

    echo "Completed Sysbench with ${INSTANCE_COUNT} concurrent instance(s). Moving to the next..."
done

echo "Test completed. Logs saved in sysbench_cpu_*_instance.log files."
