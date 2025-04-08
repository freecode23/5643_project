import matplotlib.pyplot as plt
import os
import csv
from datetime import datetime
from dateutil import parser
# Define environment types
ENV_TYPES = ["bare_metal", "docker", "minikube", "kind", "pvc-kind"]

# Define the file names for slowdown data (relative throughput log)
slowdown_file = "relative_throughput.log"

# First, read the baseline throughput from bare_metal results (assumed from 1_instance.log)
baseline_file = os.path.join("bare_metal", "results", "1_instance.log")
try:
    with open(baseline_file, "r") as f:
        # Expecting a CSV line like: "345.67,2025-04-03T21:12:00Z,2025-04-03T21:12:10Z"
        first_line = f.readline().strip()
        baseline_parts = first_line.split(",")
        baseline = float(baseline_parts[0])
except Exception as e:
    print(f"Error reading baseline throughput from {baseline_file}: {e}")
    baseline = None

if baseline is None:
    print("Baseline throughput is not available. Exiting.")
    exit(1)

print(f"Baseline throughput: {baseline} MiB/s")

# Data dictionaries for each environment
env_instances = {}       # { env: [instance_counts] }
env_slowdown = {}        # { env: [slowdown_factor] }
env_avg_throughput = {}  # { env: [average throughput] }

for env in ENV_TYPES:
    slowdown_path = os.path.join(env, "results", slowdown_file)
    instances = []
    slowdown = []
    try:
        with open(slowdown_path, "r") as file:
            for line in file:
                parts = line.strip().split(",")
                if len(parts) == 2:
                    try:
                        instances.append(int(parts[0].strip()))
                        slowdown.append(float(parts[1].strip()))
                    except ValueError:
                        continue
        if instances:
            env_instances[env] = instances
            env_slowdown[env] = slowdown
            # Compute average throughput = baseline / slowdown factor for each instance count.
            env_slowdown[env] = slowdown
            # Compute avg throughput from slowdown
            env_avg_throughput[env] = [baseline / s if s != 0 else 0 for s in slowdown]            
    except FileNotFoundError:
        print(f"Warning: File {slowdown_path} not found. Skipping environment {env}.")

# Create subplots: left for average throughput, right for slowdown factor
fig, axes = plt.subplots(1, 2, figsize=(14, 6))
ax1, ax2 = axes

# Plot Average Throughput vs Instances
for env in env_instances:
    ax1.plot(env_instances[env], env_avg_throughput[env], marker="o", linestyle="-", label=env)
ax1.set_xscale("log")
ax1.set_xlabel("Number of SysBench Instances")
ax1.set_ylabel("Average Throughput (MiB/s)")
ax1.set_title("Average Throughput vs Instances")
ax1.grid(True, which="major", axis="x", linestyle="--", linewidth=0.7)
ax1.legend()

# Plot Slowdown Factor vs Instances
for env in env_instances:
    ax2.plot(env_instances[env], env_slowdown[env], marker="o", linestyle="-", label=env)
ax2.set_xscale("log")
ax2.set_xlabel("Number of SysBench Instances")
ax2.set_ylabel("Slowdown Factor (Bare Metal 1 Instance / Avg Throughput)")
ax2.set_title("Slowdown Factor vs Instances")
ax2.grid(True, which="major", axis="x", linestyle="--", linewidth=0.7)
ax2.legend()

plt.tight_layout()
plt.savefig("comparison.png")
plt.close()

print("Plots saved as 'comparison.png'")
# -----------------------------------------
# GANTT CHART for Overlap Visualization (Fixed)
# -----------------------------------------
gantt_envs = ["bare_metal", "docker", "minikube", "kind", "pvc-kind"]
fig, axes = plt.subplots(1, len(gantt_envs), figsize=(22, 8), sharey=True)

for i, env in enumerate(gantt_envs):
    ax = axes[i]
    log_dir = os.path.join(env, "results")
    instance_times = []

    target_file = os.path.join(log_dir, "256_instance.log")
    if os.path.exists(target_file):
        try:
            with open(target_file, "r") as f:
                for line_num, line in enumerate(f):
                    parts = line.strip().split(",")
                    if len(parts) == 3:
                        _, start_str, end_str = parts
                        start = int(parser.isoparse(start_str).timestamp())
                        end = int(parser.isoparse(end_str).timestamp())
                        instance_times.append((line_num, start, end))
        except Exception as e:
            print(f"Error reading 256_instance.log in {env}: {e}")
    else:
        print(f"No 256_instance.log found in {env}")
        if not instance_times:
            ax.set_title(f"{env} (no data)")
            continue

    # Normalize to first start time
    min_start = min(start for _, start, _ in instance_times)
    for inst_id, start, end in instance_times:
        ax.barh(inst_id, end - start, left=start - min_start, height=0.8)

    ax.set_title(f"{env.replace('_', ' ').title()} (256 Instances)")
    ax.set_xlabel("Time (s since first start)")
    ax.set_xlim(left=0)
    ax.grid(True, axis='x', linestyle='--', linewidth=0.5)

axes[0].set_ylabel("Instance ID")
plt.tight_layout()
plt.savefig("overlap_gantt.png")
plt.close()
print("Gantt chart saved as 'overlap_gantt.png'")
