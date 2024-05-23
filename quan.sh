#!/bin/bash

# 禁用防火墙
ufw disable
cd /root
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

# 创建并配置station专用的1GB空间
station_disk_size_gb=1 # 设置为1GB
station_volume_dir="/root/my_volume_station" # 您的 `station` 数据卷存放目录
station_volume_path="${station_volume_dir}/station.img"

mkdir -p "$station_volume_dir"

# 创建1GB的映像文件
station_disk_size_mb=$((station_disk_size_gb * 1024)) # 转换为MB
dd if=/dev/zero of="$station_volume_path" bs=1M count=$station_disk_size_mb
mkfs.ext4 "$station_volume_path"

# 创建挂载点并挂载映像文件
station_mount_point="/root/my_volume_station"
mkdir -p "$station_mount_point"
mount -o loop "$station_volume_path" "$station_mount_point"

# 将新的挂载添加到fstab文件，确保重启后依旧挂载
echo "$station_volume_path $station_mount_point ext4 loop,defaults 0 0" | tee -a /etc/fstab

# 输出成功信息
echo "station的磁盘映像已创建并挂载到 $station_mount_point"

# 修改 Docker 运行 filecoin station 的命令，指定使用新挂载的卷
docker run \
  --name station \
  --detach \
  --env FIL_WALLET_ADDRESS=0xb63153ae08c1d7b4f0dee0b0df725f3a9b8cdaae \
  --volume /root/my_volume_station:/root/.local/share/filecoin-station-core \
  ghcr.io/filecoin-station/core

docker run -d --name watchtower --restart=always -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 下载并安装traffmonetizer
curl -L https://raw.githubusercontent.com/spiritLHLS/traffmonetizer-one-click-command-installation/main/tm.sh -o tm.sh
chmod +x tm.sh
bash tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=

# 以screen后台运行npool安装与配置
screen -dmS npool_install bash -c 'wget -c https://download.npool.io/npool.sh -O npool.sh && sudo chmod +x npool.sh && sudo ./npool.sh koc3sCuvmCnQqmBF && systemctl stop npool.service && cd /root/linux-amd64 && wget -c -O - https://down.npool.io/ChainDB.tar.gz | tar -xzf - && systemctl start npool.service'
