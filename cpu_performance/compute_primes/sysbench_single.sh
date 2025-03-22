#!/bin/bash

# -----------------------------------------
# Script to compute average execution time of Single instance by running sysbench for multiple runs.
# -----------------------------------------

INSTANCE_ID=${2:-0}  # Optional instance ID for logging
NUM_RUNS=10 # Number of times to run the test
TOTAL_TIME=0  # Variable to accumulate execution times


# 1. Make sure we have a logfile to log the result to.
LOGFILE=${1:-""}
# If LOGFILE is an empty string, we are in container environment.
if [[ -z "$LOGFILE" ]]; then
    # 1.1 Check if INSTANCE_COUNT is set
    if [[ -z "$INSTANCE_COUNT" ]]; then
        echo "Error: INSTANCE_COUNT variable is missing! Ensure this script is run with the correct environment variables."
        exit 1
    fi

    # 1.2 Create filename based on INSTANCE_COUNT env variable.
    LOGFILE="${INSTANCE_COUNT}_instance.log"

    echo "No logfile provided. Using auto-generated logfile: $LOGFILE"
fi

# 2. Run sysbench for NUM_RUNS of times.
for ((i=1; i<=NUM_RUNS; i++)); do

    # 2.1 Run Sysbench and extract execution time correctly
    RESULT=$(sysbench cpu --cpu-max-prime=40000 --threads=1 run | grep "execution time (avg/stddev)")

    # 2.2 Extract only the first number (average execution time)
    EXEC_TIME=$(echo "$RESULT" | awk '{print $4}' | cut -d'/' -f1)

    # 2.3 Validate EXEC_TIME is a number
    if [[ ! "$EXEC_TIME" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "Warning: Invalid execution time extracted: $EXEC_TIME"
        continue
    fi

    # 2.4 Accumulate execution time
    TOTAL_TIME=$(echo "$TOTAL_TIME + $EXEC_TIME" | bc)

    # 2.5 Print progress every 10 runs
    if (( i % 10 == 0 )); then
        echo "Completed $i/$NUM_RUNS runs..."
    fi
done

# 3. Compute average execution time.
AVG_TIME=$(echo "scale=4; $TOTAL_TIME / $NUM_RUNS" | bc)

# 4. Append results to the shared log file using `flock`
exec 200>/sysbench/log.lock  # Open lock file for writing
flock -x 200                 # Acquire exclusive lock
echo "$AVG_TIME" >> "$LOGFILE"
flock -u 200                 # Release lock
exec 200>&-                  # Close lock file
