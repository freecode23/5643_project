import matplotlib.pyplot as plt
import numpy as np

# Define environment types
ENV_TYPES = ["bare_metal", "docker", "k8s"]
slowdown_file = "slowdown.log"

# Create the plot
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
plt.savefig("plot.png")
