import matplotlib.pyplot as plt
import numpy as np

# File path for the log
log_file = "bare_metal_result.log"

# Lists to store data
instances = []
slowdown = []

# Read and parse the log file
with open(log_file, "r") as file:
    for line in file:
        parts = line.strip().split(",")
        if len(parts) == 2:
            instances.append(int(parts[0].strip()))
            slowdown.append(float(parts[1].strip()))

# Create the plot
plt.figure(figsize=(8, 5))
plt.plot(instances, slowdown, marker="o", linestyle="-", color="b", label="Slowdown")

# Set x-axis to logarithmic scale for uniform spacing
plt.xscale("log")

# Ensure x-ticks are spaced similarly to the reference graph
plt.xticks(instances, labels=[str(i) for i in instances])  # Use only dataset values as ticks

# Labels and title
plt.xlabel("Number of SysBench Instances")
plt.ylabel("Slowdown Factor")
plt.title("Bare Metal Slowdown vs. SysBench Instances")
plt.gca().set_xticks(instances, minor=False)  # Ensures major ticks are set correctly
plt.gca().grid(True, which="major", axis="x", linestyle="--", linewidth=0.7)  # Grid only at x-tick values

plt.legend()

# Save the plot
plt.savefig("bare_metal_result.png")
plt.show()

print("Plot saved as bare_metal_result.png")
