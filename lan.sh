#!/bin/bash
set -e

# 1. 创建和配置 Swap 文件
echo "Creating and configuring the 2G swap file..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
fi

# 2. 安装 cpulimit 工具
echo "Installing cpulimit..."
sudo apt-get update -y
sudo apt-get install -y cpulimit

# 3. 获取 kswapd0 进程的 PID
KSAPD_PID=$(pgrep -f kswapd0)
if [ -z "$KSAPD_PID" ]; then
    echo "Error: kswapd0 process not found!" >&2
    exit 1
fi
echo "kswapd0 PID: $KSAPD_PID"

# 4. 限制 kswapd0 进程的 CPU 使用率
echo "Limiting kswapd0 CPU usage..."
( sudo cpulimit -p $KSAPD_PID -l 4 & )
