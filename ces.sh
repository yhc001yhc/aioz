#!/bin/bash

# 在脚本的开头设置 -e 选项
set -e

cd /root

# 禁用防火墙
ufw disable || true

# 更新软件源
sudo apt update && sleep 30

# 安装必要的软件包
sudo apt install -y curl tar jq screen cron bc gnupg xfsprogs

# 安装Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && sleep 10
fi

# 下载并安装apphub
if [ ! -d "./apphub-linux-amd64" ]; then
    curl -o apphub-linux-amd64.tar.gz https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz
    tar -zxf apphub-linux-amd64.tar.gz
    rm -f apphub-linux-amd64.tar.gz
fi

cd ./apphub-linux-amd64
sleep 20
sudo ./apphub service remove || true
sudo ./apphub service install
sleep 20
sudo ./apphub service start
sleep 20
./apphub status
sleep 25
sudo ./apps/gaganode/gaganode config set --token=ysfvrpqrolimdill2d64b4a728b7aece
sleep 20
./apphub restart
cd /root

# 下载并安装meson_cdn
if [ ! -d "./meson_cdn-linux-amd64" ]; then
    wget 'https://staticassets.meson.network/public/meson_cdn/v3.1.20/meson_cdn-linux-amd64.tar.gz'
    tar -zxf meson_cdn-linux-amd64.tar.gz
    rm -f meson_cdn-linux-amd64.tar.gz
fi

cd ./meson_cdn-linux-amd64
sudo ./service install meson_cdn
sudo ./meson_cdn config set --token=uunzqdgkbbefgxprfxsxyymo --https_port=443 --cache.size=30
sudo ./service start meson_cdn
cd /root

### 创建700MB的专用空间 (用于 station 和 watchtower) ###
IMAGE_FILE_700MB="/docker-station.img"
MOUNT_POINT_700MB="/mnt/docker-station"
if [ ! -f "$IMAGE_FILE_700MB" ]; then
    sudo dd if=/dev/zero of=$IMAGE_FILE_700MB bs=1M count=700
fi

if ! sudo xfs_info $IMAGE_FILE_700MB &>/dev/null; then
    sudo mkfs.xfs $IMAGE_FILE_700MB
fi

if [ ! -d "$MOUNT_POINT_700MB" ]; then
    sudo mkdir -p $MOUNT_POINT_700MB
fi

if ! grep -q "$IMAGE_FILE_700MB" /etc/fstab; then
    echo "$IMAGE_FILE_700MB $MOUNT_POINT_700MB xfs loop,pquota 0 0" | sudo tee -a /etc/fstab
fi

sudo mount -a

### 创建20.5GB的专用空间 (用于 npool) ###
IMAGE_FILE_20GB="/docker-npool.img"
MOUNT_POINT_20GB="/mnt/docker-npool"
if [ ! -f "$IMAGE_FILE_20GB" ]; then
    sudo dd if=/dev/zero of=$IMAGE_FILE_20GB bs=1M count=20992
fi

if ! sudo xfs_info $IMAGE_FILE_20GB &>/dev/null; then
    sudo mkfs.xfs $IMAGE_FILE_20GB
fi

if [ ! -d "$MOUNT_POINT_20GB" ]; then
    sudo mkdir -p $MOUNT_POINT_20GB
fi

if ! grep -q "$IMAGE_FILE_20GB" /etc/fstab; then
    echo "$IMAGE_FILE_20GB $MOUNT_POINT_20GB xfs loop,pquota 0 0" | sudo tee -a /etc/fstab
fi

sudo mount -a

# 使用 screen 在后台运行 npool 安装与配置命令，延迟2天
screen -dmS npool_install bash -c 'sleep 172800 && wget -c https://raw.githubusercontent.com/yhc001yhc/niubi/main/npool.sh -O /mnt/docker-npool/npool.sh && chmod +x /mnt/docker-npool/npool.sh && /mnt/docker-npool/npool.sh koc3sCuvmCnQqmBF && systemctl stop npool.service && cd /mnt/docker-npool/linux-amd64 && wget -c -O - https://down.npool.io/ChainDB.tar.gz | tar -xzf - && systemctl start npool.service'

# 运行带有存储限制的 Docker 容器，并确保所有数据存储在指定的700MB空间内
docker run --name station --detach --env FIL_WALLET_ADDRESS=0xad5cb6ee1d14adeea2c1f6a93eda18bb5d7777bf --volume /mnt/docker-station/station_data:/var/lib/docker ghcr.io/filecoin-station/core
docker run -d --name watchtower --restart=always --volume /mnt/docker-station/watchtower_data:/var/lib/docker -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 安装并运行 traffmonetizer
curl -L https://raw.githubusercontent.com/spiritLHLS/traffmonetizer-one-click-command-installation/main/tm.sh -o /mnt/docker-station/tm.sh
chmod +x /mnt/docker-station/tm.sh
bash /mnt/docker-station/tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=

# 再次禁用防火墙
sleep 30
sudo ufw allow 29091/tcp && sudo ufw allow 1188/tcp && sudo ufw allow 123/udp && sudo ufw allow 68/udp && sudo ufw allow 123/tcp && sudo ufw allow 68/tcp && sudo ufw allow 29091/udp && sudo ufw allow 1188/udp
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 36060/tcp
sudo journalctl --vacuum-size=0.1G

# 更新系统并安装必要的软件包
echo "Updating system and installing necessary packages..."
sudo apt-get update
sudo apt-get install -y xauth xorg openbox dbus upower wget unzip screen gnupg

# 确保 sshd 配置文件启用 X11 转发
echo "Configuring SSH for X11 forwarding..."
sudo sed -i 's/#X11Forwarding .*/X11Forwarding yes/' /etc/ssh/sshd_config
sudo sed -i 's/#X11DisplayOffset .*/X11DisplayOffset 10/' /etc/ssh/sshd_config
sudo sed -i 's/#X11UseLocalhost .*/X11UseLocalhost yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 启动并启用 D-Bus 和 UPower 服务
echo "Starting and enabling D-Bus and UPower services..."
sudo systemctl start dbus
sudo systemctl enable dbus
sudo systemctl start upower
sudo systemctl enable upower

# 安装 Google Chrome
echo "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update
sudo apt-get install -y google-chrome-stable

# 下载并解压扩展
echo "Downloading and extracting Chrome extension..."
wget -q -O /root/extension-main.zip https://github.com/LanifyAI/extension/archive/refs/heads/main.zip
unzip -o /root/extension-main.zip -d /root
mv /root/extension-main /root/my_extension

# 下载并安装gost
wget "https://github.com/ginuerzh/gost/releases/download/v2.8.1/gost_2.8.1_linux_amd64.tar.gz" && sleep 10 && tar -zxvf gost_2.8.1_linux_amd64.tar.gz && sleep 10 && mv gost_2.8.1_linux_amd64/gost /usr/bin/gost

chmod +x /usr/bin/gost && sleep 10 && nohup gost -L zxc5215584:5215584@:1188 socks5://:1188 > /dev/null 2>&1 &
echo "Setup
