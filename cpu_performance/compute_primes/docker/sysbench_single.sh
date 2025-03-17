#!/bin/bash

# Script to compute the denominator for CPU metric: Execution time of Single instance on Bare-Metal.


# Set default log file if no argument is provided
LOGFILE=${1:-"default.log"}
INSTANCE_ID=${2:-0}  # Optional instance ID for logging
NUM_RUNS=1  # Number of times to run the test
TOTAL_TIME=0  # Variable to accumulate execution times

# Loop to run the test multiple times
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

# Compute average execution time
AVG_TIME=$(echo "scale=4; $TOTAL_TIME / $NUM_RUNS" | bc)

# Save results to log file
# echo "Instance $INSTANCE_ID - Average Execution Time: $AVG_TIME seconds" >> "$LOGFILE"
echo  "$AVG_TIME" >> "$LOGFILE"