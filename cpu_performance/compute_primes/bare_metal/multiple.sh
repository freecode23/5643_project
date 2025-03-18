#!/bin/bash
# To be run from compute_primes dir.


SYSBENCH_SCRIPT="sysbench_single.sh"
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)

# Run sysbench with X number of instances and log the execution time for each of the instance.
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    LOGFILE="./bare_metal/${INSTANCE_COUNT}_instance.log"
    echo -e "\n\nRunning Sysbench with ${INSTANCE_COUNT} concurrent instance(s)... Logfile: $LOGFILE"

    # Clear log file if it exists
    > "$LOGFILE"
    
    # Start multiple sysbench_single.sh instances in parallel
    for ((i=1; i<=INSTANCE_COUNT; i++)); do
        ./${SYSBENCH_SCRIPT} "$LOGFILE" "$i" &  # Pass instance ID
    done

    # Wait for all instances of the current test to finish before moving to the next
    wait

    echo "Completed Sysbench with ${INSTANCE_COUNT} concurrent instance(s). Moving to the next..."
done

echo "Test completed. Logs saved in _*_instance.log files."
