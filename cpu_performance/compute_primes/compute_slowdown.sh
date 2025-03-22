#!/bin/bash

# -----------------------------------------
# Script to compute slowdown for different system environment (bare metal, docker, or k8s)
# and plot the result
# -----------------------------------------

# -----------------------------------------
# Read the baseline execution time from a single instance in bare metal.
# -----------------------------------------
BASELINE_EXEC_TIME=$(head -n 1 "./bare_metal/1_instance.log")
if [[ ! "$BASELINE_EXEC_TIME" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid baseline execution time in 1_instance.log"
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
    RESULT_FILE="./${ENV_TYPE}/slowdown.log"

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

        # 2.2. Calculates the total execution time by summing all values in the first column of $LOGFILE
        TOTAL_EXEC_TIME=$(awk '{sum += $1} END {print sum}' "$LOGFILE")
        AVERAGE_EXEC_TIME=$(echo "scale=4; $TOTAL_EXEC_TIME / $INSTANCE_COUNT" | bc)

        # 2.3. Compute the slowdown using baseline bare metal single instance.
        SLOWDOWN=$(echo "scale=4; $BASELINE_EXEC_TIME/$AVERAGE_EXEC_TIME " | bc)

        # 2.4. Save to RESULT_FILE.3
        echo "$INSTANCE_COUNT, $SLOWDOWN" >> "$RESULT_FILE"

        # 2.4. Print result for this environment.
        echo "Instance $INSTANCE_COUNT - Slowdown: $SLOWDOWN"
    done
done

# -----------------------------------------
# Plot slowdown for all environments
# -----------------------------------------
python3 plot_result.py