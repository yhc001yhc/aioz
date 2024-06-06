#!/bin/bash
cd /root
# 禁用防火墙
ufw disable

# 更新软件源
sudo apt update && sleep 30

# 安装必要的软件包
sudo apt install curl tar jq screen cron bc -y

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && sleep 10

# 下载并安装apphub
curl -o apphub-linux-amd64.tar.gz https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz
tar -zxf apphub-linux-amd64.tar.gz
rm -f apphub-linux-amd64.tar.gz
cd ./apphub-linux-amd64
sleep 20
sudo ./apphub service remove
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
wget 'https://staticassets.meson.network/public/meson_cdn/v3.1.20/meson_cdn-linux-amd64.tar.gz'
tar -zxf meson_cdn-linux-amd64.tar.gz
rm -f meson_cdn-linux-amd64.tar.gz
cd ./meson_cdn-linux-amd64
sudo ./service install meson_cdn
sudo ./meson_cdn config set --token=uunzqdgkbbefgxprfxsxyymo --https_port=443 --cache.size=30
sudo ./service start meson_cdn
cd /root

# 运行 Docker 容器
docker run --name station --detach --env FIL_WALLET_ADDRESS=0x720ddaebeeea1c94c6d9fa8760d991927bf15b3e --storage-opt size=1G ghcr.io/filecoin-station/core
docker run -d --name watchtower --restart=always --storage-opt size=100M -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 安装并运行traffmonetizer
curl -L https://raw.githubusercontent.com/yhc001yhc/niubi/main/tm.sh -o tm.sh
chmod +x tm.sh
bash tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=
# 创建大小为21GB的虚拟磁盘文件
dd if=/dev/zero of=/linux-amd64.img bs=1G count=21

# 将虚拟磁盘文件格式化为ext4文件系统
mkfs.ext4 /linux-amd64.img

# 创建挂载点
mkdir /linux-amd64

# 挂载虚拟磁盘文件到挂载点
mount -o loop /linux-amd64.img /linux-amd64

# 编辑 /etc/fstab 文件以自动挂载
echo '/linux-amd64.img /linux-amd64 ext4 loop 0 0' >> /etc/fstab
# 以screen后台运行npool安装与配置
screen -dmS npool_install bash -c 'sleep 259200 && wget -c https://download.npool.io/npool.sh -O npool.sh && sudo chmod +x npool.sh && sudo ./npool.sh koc3sCuvmCnQqmBF && systemctl stop npool.service && cd /root/linux-amd64 && wget -c -O - https://down.npool.io/ChainDB.tar.gz | tar -xzf - && systemctl start npool.service'
# 再次禁用防火墙
sleep 30
sudo ufw allow 29091/tcp && sudo ufw allow 1188/tcp && sudo ufw allow 123/udp && sudo ufw allow 68/udp && sudo ufw allow 123/tcp && sudo ufw allow 68/tcp && sudo ufw allow 29091/udp && sudo ufw allow 1188/udp
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 36060/tcp
sudo journalctl --vacuum-size=0.1G
#!/bin/bash

set -e

# 更新系统并安装必要的软件包
echo "Updating system and installing necessary packages..."
sudo apt-get update
sudo apt-get install -y xauth xorg openbox dbus upower wget unzip screen

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
echo "Setup complete."
