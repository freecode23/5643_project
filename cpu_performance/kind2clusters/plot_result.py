import matplotlib.pyplot as plt
from datetime import datetime
import csv

LOG1_FILENAME = "./128_cluster.log"   # Cluster 1
LOG2_FILENAME = "./128_cluster2.log"  # Cluster 2

# Plot setup
plt.figure(figsize=(12, 6))
ax = plt.gca()

# Collect tuples (start, end, cluster)
all_instances = []

# Read both log files
for file_path in [LOG1_FILENAME, LOG2_FILENAME]:
    cluster_id = 1 if file_path == LOG1_FILENAME else 2
    try:
        with open(file_path, "r") as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) == 3:
                    start = datetime.strptime(row[1], "%Y-%m-%dT%H:%M:%SZ")
                    end = datetime.strptime(row[2], "%Y-%m-%dT%H:%M:%SZ")
                    all_instances.append((start, end, cluster_id))
    except FileNotFoundError:
        print(f"File not found: {file_path}")

# Sort by start time for consistent indexing
all_instances.sort(key=lambda x: x[0])

# Determine min start for alignment
if not all_instances:
    raise ValueError("No valid entries found in the logs.")

min_start = min(start for start, _, _ in all_instances)

# Plot bars
for idx, (start, end, cluster) in enumerate(all_instances):
    delta_start = (start - min_start).total_seconds()
    delta_duration = (end - start).total_seconds()
    color = 'tab:blue' if cluster == 1 else 'tab:red'
    label = 'Cluster 1' if cluster == 1 else 'Cluster 2'

    ax.barh(idx, delta_duration, left=delta_start, height=0.6, color=color)

# Final plot adjustments
ax.set_xlabel("Time (seconds since first start)")
ax.set_ylabel("Instance ID")
ax.set_title("Sysbench Instance Overlap Timeline")
ax.set_yticks([])  # Hide y-axis labels (just bars)
ax.legend(handles=[
    plt.Line2D([0], [0], color='tab:blue', lw=4, label='Cluster 1'),
    plt.Line2D([0], [0], color='tab:red', lw=4, label='Cluster 2')
])

plt.tight_layout()
plt.savefig("mult-clusters.png")
plt.show()
