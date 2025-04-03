#!/bin/bash

# -----------------------------------------
# Script to compute slowdown for different system environment (bare metal, docker, or k8s)
# and plot the result
# -----------------------------------------

# -----------------------------------------
# Read the baseline execution time from a single instance in bare metal.
# -----------------------------------------
# Read the first field (execution time) from the first line
BASELINE_MBPS=$(cut -d',' -f1 < ./bare_metal/1_instance.log)
if [[ ! "$BASELINE_MBPS" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid baseline MB/S in 1_instance.log"
    exit 1
fi


# -----------------------------------------
# Calculate Slowdown and Save to RESULT_FILE for each environment.
# -----------------------------------------

# Make sure there is "x_instance.log" in the directories in ENV_TYPES
ENV_TYPES=("bare_metal" "docker" "k8s")
INSTANCE_COUNTS=(1 2 4 8 16 32 64 128 256)

for ENV_TYPE in "${ENV_TYPES[@]}"; do
    # 0. Define path for the result of slowdown for each environment.
    RESULT_FILE="./${ENV_TYPE}/relative_throughput.log"

    # 1. Create or clear RESULT_FILE
    > "$RESULT_FILE"

    # 2. Compute slowdown for each instance count
    echo -e "\n\n${ENV_TYPE}:"
    for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
        LOGFILE="./${ENV_TYPE}/${INSTANCE_COUNT}_instance.log"

        # 2.1. Ensure the execution time log file exists
        if [[ ! -f "$LOGFILE" ]]; then
            echo "Warning: Log file $LOGFILE not found. Skipping..."
            continue
        fi

        # 2.2. Calculates the total MBPS by summing all values in the first column of $LOGFILE then finding the average 
        TOTAL_MBPS=$(awk '{sum += $1} END {print sum}' "$LOGFILE")
        AVERAGE_MBPS=$(echo "scale=4; $TOTAL_MBPS / $INSTANCE_COUNT" | bc)

        # 2.3. Compute the relative performance using baseline bare metal single instance.
        RELATIVE_PERFORMANCE=$(echo "scale=4; $BASELINE_MBPS/$AVERAGE_MBPS " | bc)

        # 2.4. Save to RESULT_FILE.3
        echo "$INSTANCE_COUNT, $RELATIVE_PERFORMANCE">> "$RESULT_FILE"

        # 2.4. Print result for this environment.
        echo "Instance $INSTANCE_COUNT - Relative Throughput: $RELATIVE_PERFORMANCE"
    done
done

# -----------------------------------------
# Plot slowdown for all environments
# -----------------------------------------
python3 plot_result.py
