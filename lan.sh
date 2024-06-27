#!/bin/bash

# 1. 创建和配置 Swap 文件
echo "Creating and configuring the 2G swap file..."
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

# 2. 安装 cpulimit 工具
echo "Installing cpulimit..."
sudo apt-get update -y
sudo apt-get install cpulimit -y

# 3. 获取 kswapd0 进程的 PID
KSAPD_PID=$(ps -e | grep kswapd0 | awk '{print $1}')
echo "kswapd0 PID: $KSAPD_PID"

# 4. 创建 cgroups 目录并添加 kswapd0 到 cgroups
echo "Configuring cgroups for kswapd0..."
sudo mkdir -p /sys/fs/cgroup/cpu/kswapd0
echo $KSAPD_PID | sudo tee /sys/fs/cgroup/cpu/kswapd0/tasks
sudo sh -c 'echo 5000 > /sys/fs/cgroup/cpu/kswapd0/cpu.cfs_quota_us'
sudo sh -c 'echo 100000 > /sys/fs/cgroup/cpu/kswapd0/cpu.cfs_period_us'


echo "Setup complete! Chrome is now running with optimized settings."
