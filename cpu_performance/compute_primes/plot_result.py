import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime
import csv
import os

# Define environment types
ENV_TYPES = ["bare_metal", "docker", "k8s"]

# -----------------------------------------
# Create the Slowdown factor plot
# -----------------------------------------
slowdown_file = "slowdown.log"
plt.figure(figsize=(8, 5))

for env in ENV_TYPES:
    slowdown_path = f"./{env}/{slowdown_file}"

    # Lists to store data
    instances = []
    slowdown = []

    try:
        # Read and parse the log file
        with open(slowdown_path, "r") as file:
            for line in file:
                parts = line.strip().split(",")
                if len(parts) == 2:
                    instances.append(int(parts[0].strip()))
                    slowdown.append(float(parts[1].strip()))

        # Plot the data
        plt.plot(instances, slowdown, marker="o", linestyle="-", label=f"{env}")

    except FileNotFoundError:
        print(f"Warning: File {slowdown_path} not found. Skipping {env}.")

# Set x-axis to logarithmic scale for uniform spacing
plt.xscale("log")

# Set x-ticks dynamically based on collected instances
if instances:
    plt.xticks(instances, labels=[str(i) for i in instances])

# Labels and title
plt.xlabel("Number of SysBench Instances")
plt.ylabel("Slowdown Factor")
plt.title("Slowdown vs. SysBench Instances")

# Grid styling
plt.grid(True, which="major", axis="x", linestyle="--", linewidth=0.7)  

# Show legend
plt.legend()

# Save the plot
plt.savefig("slowdown.png")


# -----------------------------------------
# TODO: Create the Overlap 3 Gantt chart only for 256 instances for each environment.
# Plot 3 figures in 1 image. Place them side by side.
# -----------------------------------------
LOG_FILENAME = "256_instance.log"


# Set up a horizontal layout for 3 subplots
fig, axes = plt.subplots(1, 3, figsize=(18, 10), sharey=True)

for i, env in enumerate(ENV_TYPES):
    ax = axes[i]
    file_path = os.path.join(env, LOG_FILENAME)

    try:
        with open(file_path, "r") as f:
            reader = csv.reader(f)
            rows = list(reader)

            # Get all start/end times
            times = [
                (datetime.strptime(row[1], "%Y-%m-%dT%H:%M:%SZ"),
                 datetime.strptime(row[2], "%Y-%m-%dT%H:%M:%SZ"))
                for row in rows if len(row) == 3
            ]

            if not times:
                continue

            min_start = min(start for start, _ in times)

            for idx, (start, end) in enumerate(times):
                delta_start = (start - min_start).total_seconds()
                delta_duration = (end - start).total_seconds()
                ax.barh(idx, delta_duration, left=delta_start, height=0.6)

            ax.set_title(f"{env.replace('_', ' ').title()} (256 Instances)")
            ax.set_xlabel("Time (s since first start)")
            ax.grid(True)

    except FileNotFoundError:
        ax.set_title(f"{env.replace('_', ' ').title()} - File Not Found")
        ax.axis("off")

axes[0].set_ylabel("Instance ID")
plt.tight_layout()
plt.savefig("overlap.png")


