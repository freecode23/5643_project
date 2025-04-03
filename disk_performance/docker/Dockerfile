# Use Ubuntu as the base image
FROM ubuntu:latest

# Set the working directory inside the container
WORKDIR /sysbench

# Install necessary packages (Sysbench, Bash, and bc for calculations)
RUN apt update && apt install -y \
    sysbench \
    bash \
    bc \
    procps \
    util-linux \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Copy sysbench_single.sh from current dir
COPY sysbench_single.sh .

# Ensure sysbench_single.sh is executable
RUN chmod +x sysbench_single.sh

# Default command (overridden by docker-compose)
ENTRYPOINT ["/sysbench/sysbench_single.sh"]
