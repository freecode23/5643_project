#!/bin/bash
# To be run from compute_primes dir.


SYSBENCH_SCRIPT="sysbench_single.sh"
LOGFILE_PREFIX="bm"
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256 512)

# Run sysbench with X number of instances and log the execution time for each of the instance.
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    LOGFILE="./bare_metal/${LOGFILE_PREFIX}_${INSTANCE_COUNT}_instance.log"
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

echo "Test completed. Logs saved in ${LOGFILE_PREFIX}_*_instance.log files."

# -----------------------------------------
# Calculate Slowdown and Save to RESULT_FILE
# -----------------------------------------

RESULT_FILE="./bare_metal/result.log"

# 1. Create or Clear RESULT_FILE
> "$RESULT_FILE"

# 2. Read the baseline execution time from a single instance
BASELINE_EXEC_TIME=$(head -n 1 "./bare_metal/${LOGFILE_PREFIX}_1_instance.log")

if [[ ! "$BASELINE_EXEC_TIME" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid baseline execution time in bm_1_instance.log"
    exit 1
fi

echo "Baseline Execution Time: $BASELINE_EXEC_TIME seconds"

# Compute Slowdown for Each Instance Count
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
    LOGFILE="./bare_metal/bm_${INSTANCE_COUNT}_instance.log"

    # 3.1. Ensure the log file exists
    if [[ ! -f "$LOGFILE" ]]; then
        echo "Warning: Log file $LOGFILE not found. Skipping..."
        continue
    fi

    # 3.2. Compute the average execution time
    TOTAL_EXEC_TIME=$(awk '{sum += $1} END {print sum}' "$LOGFILE")
    AVERAGE_EXEC_TIME=$(echo "scale=4; $TOTAL_EXEC_TIME / $INSTANCE_COUNT" | bc)

    # 3.3. Compute the slowdown
    SLOWDOWN=$(echo "scale=4; $BASELINE_EXEC_TIME/$AVERAGE_EXEC_TIME " | bc)

    # 3.4. Save to RESULT_FILE
    echo "$INSTANCE_COUNT, $SLOWDOWN" >> "$RESULT_FILE"
    echo "Instance $INSTANCE_COUNT - Slowdown: $SLOWDOWN"
done

