# 5643 Project
## CPU and File I/O Performance across Bare Metal, Docker, and Kubernetes

This project evaluates CPU and File I/O performance across different environments: **Bare Metal, Docker, and Kubernetes (K8s)** using [Sysbench](https://github.com/akopytov/sysbench).

---

## 0. Prerequisites
Ensure the following dependencies are installed before running the experiments.

### 0.1 Install Sysbench
```
sudo apt update
sudo apt install sysbench -y
```

### 0.2 Install Minikube
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

Verify installation:
```
minikube version
```

### 0.3 Install Kubectl
```
sudo apt update
sudo apt install -y curl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

Verify installation:
```
kubectl version --client
```

---

## 1. CPU Performance Evaluation

### 1.1 Computing Primes Performance

#### 1.1.1 Bare Metal Execution
Inside `compute_primes` directory run:
```
./bare_metal/multiple.sh
```

#### 1.1.2 Docker Execution
Inside `docker` directory run:
```
./multiple.sh
```

#### 1.1.3 Kubernetes (Minikube) Execution
Inside `k8s` directory run:
```
./multiple.sh
```

#### 1.1.4 Compute Slowdown and Plot Result
Inside `compute_primes` directory run:
```
./compute_slowdown.sh
```

---
### 1.2 Compression Algorithm
---
#### 1.2.2 Docker Execution
Inside `docker` directory run:
```
./multiple.sh
```

---

### 2. File IO Performances


---


#### 2.2.2 Docker Execution
Inside `docker` directory run:
```
./multiple.sh
```

## References
Sysbench:  
https://github.com/akopytov/sysbench

IEEE paper for computing Primes using Sysbench:  
https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7371699
