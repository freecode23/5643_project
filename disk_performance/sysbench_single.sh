#!/bin/bash

# -----------------------------------------
# Script to compute average disk I/O performance by running sysbench multiple times.
# -----------------------------------------

INSTANCE_ID=${2:-0}  # Optional instance ID for logging
NUM_RUNS=5 # Number of times to run the test (less to reduce excessive disk stress)
TOTAL_MBPS=0  # Variable for disk speed in MBPS


# 1. Make sure we have a logfile to log the result to.
LOCKFILE="$(realpath ./bare_metal/log.lock)"
LOGFILE="$(realpath ./bare_metal/${INSTANCE_COUNT}_instance.log)"
# If LOGFILE is an empty string, we are in container environment.
if [[ -z "$LOGFILE" ]]; then
    # 1.1 Check if INSTANCE_COUNT is set
    if [[ -z "$INSTANCE_COUNT" ]]; then
        echo "Error: INSTANCE_COUNT variable is missing! Ensure this script is run with the correct environment variables."
        exit 1
    fi

    # 1.2 Create filename based on INSTANCE_COUNT env variable.
    LOGFILE="${INSTANCE_COUNT}_instance.log"
    LOCKFILE="/sysbench/log.lock"

    echo "No logfile provided. Using auto-generated logfile: $LOGFILE"
fi

# 2. Setup working directory per instance
# Determine the working directory.
# If SYSBENCH_WORK_DIR is set (for Docker/KIND/minikube), use that. Otherwise, use a default.
if [[ -z "$SYSBENCH_WORK_DIR" ]]; then
    WORK_DIR="./bare_metal/tmp/instance_${INSTANCE_ID}"
else
    WORK_DIR="${SYSBENCH_WORK_DIR}/instance_${INSTANCE_ID}"
fi
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || { echo "Failed to cd into $WORK_DIR"; exit 1; }
    
# 3. Record start time
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 4. Run file I/O benchmark
for ((i=1; i<=NUM_RUNS; i++)); do
    # 4.1 Prepare test files
    sysbench fileio \
        --file-total-size=256M \
        --file-test-mode=rndrw \
        --file-block-size=4K \
        --file-num=4 \
        --file-extra-flags=direct \
        --file-fsync-freq=0 \
        --threads=1 \
        --file-io-mode=async \
        --file-async-backlog=128 \
        prepare > /dev/null

    # 4.2 Run benchmark and extract MB/s
    RESULT=$(sysbench fileio \
        --file-total-size=256M \
        --file-test-mode=rndrw \
        --file-block-size=4K \
        --file-num=4 \
        --file-extra-flags=direct \
        --file-fsync-freq=0 \
        --threads=1 \
        --file-io-mode=async \
        --file-async-backlog=128 \
        --time=10 \
        --max-requests=0 \
        run)

    # 4.3 Calculate total throughput from read and write
    read_line=$(echo "$RESULT" | grep "read, MiB/s:")
    write_line=$(echo "$RESULT" | grep "written, MiB/s:")

    read_mibps=$(echo "$read_line" | awk -F':' '{print $2}' | xargs)
    write_mibps=$(echo "$write_line" | awk -F':' '{print $2}' | xargs)

    if [[ -n "$read_mibps" && -n "$write_mibps" ]]; then
        MBPS=$(echo "scale=2; $read_mibps + $write_mibps" | bc)
    elif [[ -n "$read_mibps" ]]; then
        MBPS=$read_mibps
    elif [[ -n "$write_mibps" ]]; then
        MBPS=$write_mibps
    else
        MBPS="0.00"
    fi

    echo "Total Throughput: $MBPS MiB/s"


    # 4.4 Cleanup files
    sysbench fileio cleanup > /dev/null
  
    # 4.5 Calculate total throughput
    if [[ "$MBPS" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        TOTAL_MBPS=$(echo "$TOTAL_MBPS + $MBPS" | bc)
    fi
done

# 5. Record end time
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 6. Compute average MBPS.
AVG_MBPS=$(echo "scale=2; $TOTAL_MBPS / $NUM_RUNS" | bc)


# 7. Append results to the shared log file using `flock`
exec 200> "$LOCKFILE"    # Open lock file for writing
flock -x 200                 # Acquire exclusive lock
echo "${AVG_MBPS},${START_TIME},${END_TIME}" >> "$LOGFILE"
flock -u 200                 # Release lock
exec 200>&-                  # Close lock file

# 8. Remove working dir
rm -rf "$WORK_DIR"
