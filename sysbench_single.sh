#!/bin/bash

# Script to compute the denominator for CPU metric: Execution time of Single instance on Bare-Metal.
# .

# Output file
LOGFILE="sysbench_cpu_bare_metal.log"
NUM_RUNS=10  # Number of times to run the test (reduce to 10 for testing)
TOTAL_TIME=0  # Variable to accumulate execution times

echo "Running Sysbench CPU benchmark ($NUM_RUNS times)..."

# Loop to run the test multiple times
for ((i=1; i<=NUM_RUNS; i++))
do
    # Run Sysbench and extract execution time correctly
    RESULT=$(sysbench cpu --threads=1 run | grep "execution time (avg/stddev)")

    # Extract only the first number (average execution time)
    EXEC_TIME=$(echo "$RESULT" | awk '{print $4}' | cut -d'/' -f1)

    # Print the extracted execution time for debugging
    echo "Execution time extracted: $EXEC_TIME"

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
echo "Average Execution Time after $NUM_RUNS runs: $AVG_TIME seconds" | tee -a "$LOGFILE"

# Print final result
echo "Test completed. Average execution time saved in $LOGFILE"
