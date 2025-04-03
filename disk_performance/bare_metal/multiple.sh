#!/bin/bash
# To be run from disk dir.

SYSBENCH_SCRIPT="sysbench_single.sh"
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)

LOG_DIR="./bare_metal"
TOTAL_LOGFILE="$LOG_DIR/start_end_per_instance.log"
> "$TOTAL_LOGFILE"

sudo chown -R $USER:$USER .
# Run sysbench with X number of instances and log the execution time for each of the instance.
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    # 1. Init log file.
    LOGFILE="$LOG_DIR/${INSTANCE_COUNT}_instance.log"
    echo -e "\n\nRunning Sysbench with ${INSTANCE_COUNT} concurrent instance(s)... Logfile: $LOGFILE"

    # 2. Clear log file if it exists
    > "$LOGFILE"

    # 3. Record start time
    START_EPOCH=$(date +%s)
    
    # 4. Start multiple sysbench_single.sh instances in parallel
    for ((i=1; i<=INSTANCE_COUNT; i++)); do
      INSTANCE_DIR="./bare_metal/tmp/instance_$i"
      mkdir -p "$INSTANCE_DIR"  
      ./${SYSBENCH_SCRIPT} "$LOGFILE" "$i" &  # Pass instance ID
    done

    # 5. Wait for all instances of the current test to finish before moving to the next
    wait

    # 6. Record end time
    END_EPOCH=$(date +%s)
    DURATION=$((END_EPOCH - START_EPOCH))

    # 7. Log as csv
    echo "${INSTANCE_COUNT},${DURATION}" >> "$TOTAL_LOGFILE"

    echo "Completed Sysbench with ${INSTANCE_COUNT} concurrent instance(s). Moving to the next..."
done

echo "Test completed. Logs saved in _*_instance.log files."

# Clean up.
rm ./bare_metal/log.lock
