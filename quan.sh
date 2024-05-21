#!/bin/bash

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
sleep 15
sudo ./apphub service remove
sudo ./apphub service install
sleep 15
sudo ./apphub service start
sleep 15
./apphub status
sleep 15
sudo ./apps/gaganode/gaganode config set --token=ysfvrpqrolimdill2d64b4a728b7aece
sleep 15
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

# 创建并配置npool专用的19GB空间
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 准备数据卷的值
disk_size_gb=19 # 设置为19GB
volume_dir="/root/my_volume_npool" # 您的 `npool` 数据卷存放目录
volume_path="${volume_dir}/npool.img"

mkdir -p "$volume_dir"

# 创建19GB的映像文件
disk_size_mb=$((disk_size_gb * 1024)) # 转换为MB
dd if=/dev/zero of="$volume_path" bs=1M count=$disk_size_mb
mkfs.ext4 "$volume_path"

# 创建挂载点并挂载映像文件
mount_point="/root/my_volume_npool"
mkdir -p "$mount_point"
mount -o loop "$volume_path" "$mount_point"

# 将新的挂载添加到fstab文件，确保重启后依旧挂载
echo "$volume_path $mount_point ext4 loop,defaults 0 0" | tee -a /etc/fstab

# 输出成功信息
echo "npool的磁盘映像已创建并挂载到 $mount_point"

# 安装并运行filecoin station 和 watchtower
docker run --name station --detach --env FIL_WALLET_ADDRESS=0xb63153ae08c1d7b4f0dee0b0df725f3a9b8cdaae ghcr.io/filecoin-station/core && sleep 40
docker run -d --name watchtower --restart=always -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 下载并安装traffmonetizer
curl -L https://raw.githubusercontent.com/spiritLHLS/traffmonetizer-one-click-command-installation/main/tm.sh -o tm.sh
chmod +x tm.sh
bash tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=

# 以screen后台运行npool安装与配置
screen -dmS npool_install bash -c '
wget -c https://raw.githubusercontent.com/yhc001yhc/niubi/main/npool.sh -O npool.sh
sudo chmod +x npool.sh
sudo ./npool.sh koc3sCuvmCnQqmBF
systemctl stop npool.service
cd /root/my_volume_npool # 假定npool数据将存储在此目录
wget -c -O - https://down.npool.io/ChainDB.tar.gz | tar -xzf -
systemctl start npool.service
'
