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
### 1.1 Sysbench

#### 1.1.1 Bare Metal
Inside compute_primes directory run:
```
./bare_metal/bm_multiple.sh
```

#### 1.1.2 Docker
Navigate to the docker directory and run:

docker-compose up --build --scale sysbench=5
#### 1.1.3 K8s





## References
CPU sysbench:
https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7371699

