#!/bin/bash

# Script to compute the denominator for CPU metric: Execution time of Single instance on Bare-Metal.


INSTANCE_ID=${2:-0}  # Optional instance ID for logging
NUM_RUNS=1  # Number of times to run the test
TOTAL_TIME=0  # Variable to accumulate execution times


# 1. Make sure we have a logfile to log the result to.
LOGFILE=${1:-""}
# If LOGFILE is an empty string, we are in container environment.
if [[ -z "$LOGFILE" ]]; then
    # Check if INSTANCE_COUNT is set
    if [[ -z "$INSTANCE_COUNT" ]]; then
        echo "Error: INSTANCE_COUNT variable is missing! Ensure this script is run with the correct environment variables."
        exit 1
    fi

    # Create filename based on INSTANCE_COUNT env variable.
    LOGFILE="docker_${INSTANCE_COUNT}_instance.log"

    # Clear log file if it exists
    > "$LOGFILE"
    
    echo "No logfile provided. Using auto-generated logfile: $LOGFILE"
fi

# 2. Run sysbench for NUM_RUNS of times.
for ((i=1; i<=NUM_RUNS; i++))
do
    # Run Sysbench and extract execution time correctly
    RESULT=$(sysbench cpu --cpu-max-prime=40000 --threads=1 run | grep "execution time (avg/stddev)")

    # Extract only the first number (average execution time)
    EXEC_TIME=$(echo "$RESULT" | awk '{print $4}' | cut -d'/' -f1)

    # Validate EXEC_TIME is a number
    if [[ ! "$EXEC_TIME" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "Warning: Invalid execution time extracted: $EXEC_TIME"
        continue
    fi

    # Accumulate execution time
    TOTAL_TIME=$(echo "$TOTAL_TIME + $EXEC_TIME" | bc)

    # Print progress every 10 runs
    if (( i % 10 == 0 )); then
        echo "Completed $i/$NUM_RUNS runs..."
    fi
done

# 3. Compute average execution time.
AVG_TIME=$(echo "scale=4; $TOTAL_TIME / $NUM_RUNS" | bc)

# 4. Save results to log file
echo  "$AVG_TIME" >> "$LOGFILE"
