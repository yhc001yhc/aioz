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

# 5. 调整系统 vm.swappiness 参数
echo "Adjusting vm.swappiness to 10..."
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# 6. 启动 Chrome 并限制其 CPU 使用率
echo "Starting Chrome with optimized settings and restricting CPU usage..."
( sudo cpulimit -e chrome -l 50 & )

# 启动 Chrome 并保持其在前台运行，以便用户可以交互
google-chrome --no-sandbox --disable-plugins --disable-background-timer-throttling --disable-sync --disable-background-networking --disable-site-isolation-trails --disable-default-apps --disable-gpu --single-process --memory-pressure-thresholds=low --enable-low-end-device-mode --load-extension=/root/my_extension --homepage=https://app.lanify.ai/ --new-tab https://app.lanify.ai/
 &

# 获取 Chrome 的 PID 并 disown 它
CHROME_PID=$!
disown $CHROME_PID

echo "Setup complete! Chrome is now running with optimized settings."
