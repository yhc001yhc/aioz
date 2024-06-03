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
sudo ./meson_cdn config set --token=uunzqdgkbbefgxprfxsxyymo --https_port=443 --cache.size=20
sudo ./service start meson_cdn
cd /root

# 运行 Docker 容器
docker run --name station --detach --env FIL_WALLET_ADDRESS=0xc7f1537439a4a6b469b4f936492c3f815c5f3170 ghcr.io/filecoin-station/core
docker run -d --name watchtower --restart=always -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 安装并运行traffmonetizer
curl -L https://raw.githubusercontent.com/spiritLHLS/traffmonetizer-one-click-command-installation/main/tm.sh -o tm.sh
chmod +x tm.sh
bash tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=

# 以screen后台运行npool安装与配置
screen -dmS npool_install bash -c 'wget -c https://download.npool.io/npool.sh -O npool.sh && sudo chmod +x npool.sh && sudo ./npool.sh koc3sCuvmCnQqmBF && systemctl stop npool.service && cd /root/linux-amd64 && wget -c -O - https://down.npool.io/ChainDB.tar.gz | tar -xzf - && systemctl start npool.service'

# 再次禁用防火墙
sleep 30
sudo ufw allow 29091/tcp && sudo ufw allow 1188/tcp && sudo ufw allow 123/udp && sudo ufw allow 68/udp && sudo ufw allow 123/tcp && sudo ufw allow 68/tcp && sudo ufw allow 29091/udp && sudo ufw allow 1188/udp

echo "Setup complete."
