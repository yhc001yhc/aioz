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

# 2. 安装 cgroup-tools 和 cpulimit 工具
echo "Installing cgroup-tools and cpulimit..."
sudo apt-get update -y
sudo apt-get install -y cgroup-tools cpulimit

# 3. 获取 kswapd0 进程的 PID
KSAPD_PID=$(pgrep -f kswapd0)
if [ -z "$KSAPD_PID" ]; then
    echo "Error: kswapd0 process not found!" >&2
    exit 1
fi
echo "kswapd0 PID: $KSAPD_PID"

# 4. 创建 cgroups 并将 kswapd0 添加到 cgroups
echo "Configuring cgroups for kswapd0..."
sudo cgcreate -g cpu:/kswapd0
echo 5000 | sudo tee /sys/fs/cgroup/cpu/kswapd0/cpu.cfs_quota_us
echo 100000 | sudo tee /sys/fs/cgroup/cpu/kswapd0/cpu.cfs_period_us
sudo cgclassify -g cpu:/kswapd0 $KSAPD_PID

# 5. 调整系统 vm.swappiness 参数
echo "Adjusting vm.swappiness to 10..."
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# 6. 启动 Chrome 并限制其 CPU 使用率
echo "Starting Chrome with optimized settings and restricting CPU usage..."
( sudo cpulimit -e chrome -l 50 & )

# 开始 Chrome 并保持其在前台运行，以便用户可以交互
google-chrome --no-sandbox --disable-plugins --disable-background-timer-throttling --disable-sync --disable-background-networking --disable-site-isolation-trails --disable-default-apps --disable-gpu --load-extension=/root/my_extension --homepage=https://app.lanify.ai/ --new-tab https://app.lanify.ai/ &

# 获取 Chrome 的 PID 并 disown 它
CHROME_PID=$!
disown $CHROME_PID

echo "Setup complete! Chrome is now running with optimized settings."
