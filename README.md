# 5643_project
CPU and File I/O Performance across Bare Metal, Docker, K8s 

https://github.com/akopytov/sysbench

# Prerequisites

Install Sysbench
```
sudo apt update
sudo apt install sysbench -y
```

## 1. CPU performance
### 1.1 Computing Primes

#### 1.1.1 Bare Metal
Inside `compute_primes` directory run:
```
./bare_metal/multiple.sh
```

#### 1.1.2 Docker
Inside `docker` directory and run:
```
./multiple.sh
```

#### 1.1.3 K8s


#### 1.1.4 Compute slowdown for all the three environemnts
Inside `compute_primes` directory run:
```
./compute_slowdown.sh
```



### 1.2 Compression Algorithm





## References
CPU sysbench:
https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7371699

