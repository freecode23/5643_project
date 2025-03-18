#!/bin/bash

# -----------------------------------------
# Calculate Slowdown and Save to RESULT_FILE
# -----------------------------------------

ENV_TYPES=("bare_metal" "docker")

INSTANCE_COUNTS=(1 2 4 8)

for ENV_TYPE in "${ENV_TYPES[@]}"; do
    # 0. Define path for the result of slowdown for each environment.
    RESULT_FILE="./${ENV_TYPE}/slowdown.log"

    # 1. Create or Clear RESULT_FILE
    > "$RESULT_FILE"

    # 2. Read the baseline execution time from a single instance
    BASELINE_EXEC_TIME=$(head -n 1 "./${ENV_TYPE}/1_instance.log")
    if [[ ! "$BASELINE_EXEC_TIME" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid baseline execution time in 1_instance.log"
        exit 1
    fi
    echo -e "\n\n${ENV_TYPE}:"


    # 3. Compute Slowdown for Each Instance Count
    for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do
        LOGFILE="./${ENV_TYPE}/${INSTANCE_COUNT}_instance.log"

        # 3.1. Ensure the log file exists
        if [[ ! -f "$LOGFILE" ]]; then
            echo "Warning: Log file $LOGFILE not found. Skipping..."
            continue
        fi

        # 3.2. Compute the average execution time with 4 decimal point
        TOTAL_EXEC_TIME=$(awk '{sum += $1} END {print sum}' "$LOGFILE")
        AVERAGE_EXEC_TIME=$(echo "scale=4; $TOTAL_EXEC_TIME / $INSTANCE_COUNT" | bc)

        # 3.3. Compute the slowdown
        SLOWDOWN=$(echo "scale=4; $BASELINE_EXEC_TIME/$AVERAGE_EXEC_TIME " | bc)

        # 3.4. Save to RESULT_FILE
        echo "$INSTANCE_COUNT, $SLOWDOWN" >> "$RESULT_FILE"
        echo "Instance $INSTANCE_COUNT - Slowdown: $SLOWDOWN"
    done
done