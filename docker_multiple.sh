#!/bin/bash

# Get the directory where this script is located
LOCAL_DIR="$(pwd)/docker"

# ------------------------------
# Copy sysbench_single.sh from parent directory to current directory
# ------------------------------
PARENT_DIR="$(dirname "$LOCAL_DIR")"  # One level up from docker/
SYSBENCH_SCRIPT="$PARENT_DIR/sysbench_single.sh"
if [[ -f "$SYSBENCH_SCRIPT" ]]; then
    echo "📂 Copying sysbench_single.sh to docker directory..."
    cp "$SYSBENCH_SCRIPT" "$LOCAL_DIR/"
else
    echo "❌ Error: sysbench_single.sh not found in parent directory!"
    exit 1
fi


# ------------------------------
# Run multiple docker container each running a single sysbench_single program.
# ------------------------------
IMAGE_NAME="c"
INSTANCE_COUNTS=(1 2)

# Sets the build context to "$LOCAL_DIR" (which is the docker/ directory).

# Loop through each instance count
for INSTANCE_COUNT in "${INSTANCE_COUNTS[@]}"; do


    # Set log file for this instance:
    LOGFILE="/sysbench/docker_${INSTANCE_COUNT}_instance.log"

    # Clear log file if it exists
    > "$LOGFILE"

    # # TODO: For each instance i, build  run container concurrently:
    for ((i=1; i<=INSTANCE_COUNT; i++)); do

        docker build -t $IMAGE_NAME -f "$LOCAL_DIR/Dockerfile" "$LOCAL_DIR"


        # Run the container and mount logs to the local machine:
        docker run -v "$LOCAL_DIR:/sysbench" $IMAGE_NAME $LOGFILE
    done

done


# ------------------------------
# Delete sysbench_single.sh in the current directory (Cleanup)
# ------------------------------
if [[ -f "$LOCAL_DIR/sysbench_single.sh" ]]; then
    echo "🗑️  Cleaning up sysbench_single.sh..."
    rm "$LOCAL_DIR/sysbench_single.sh"
    echo "✅ Cleanup complete."
else
    echo "⚠️  Warning: sysbench_single.sh was not found in $LOCAL_DIR."
fi