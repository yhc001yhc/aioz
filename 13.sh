#!/bin/bash

# 在脚本的开头设置 -e 选项
set -e

cd /root
# 检查是否安装了 ufw
if ! command -v ufw &> /dev/null
then
    echo "ufw 未安装，现在开始安装它..."
    
    # 更新软件包列表
    sudo apt-get update
    
    # 安装 ufw
    sudo apt-get install -y ufw
    
    echo "ufw 安装完成。"
else
    echo "ufw 已经安装。"
fi
# 禁用防火墙
sudo ufw allow 29091/tcp && sudo ufw allow 1188/tcp && sudo ufw allow 123/udp && sudo ufw allow 68/udp && sudo ufw allow 123/tcp && sudo ufw allow 68/tcp && sudo ufw allow 29091/udp && sudo ufw allow 1188/udp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 36060/tcp
ufw allow 30001:30005/tcp > /dev/null 2>&1
ufw allow 30001:30005/udp > /dev/null 2>&1
ufw allow 22 > /dev/null 2>&1
ufw allow 80 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw allow 32768:65535/tcp > /dev/null 2>&1
ufw allow 32768:65535/udp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

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
sudo ./apphub service remove || true # 忽略可能的移除失败
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



# 运行带有存储限制的 Docker 容器
docker run --name station --detach --env FIL_WALLET_ADDRESS=0xf47e8fe222de29df02d883c7bf0cc9b8db4bceeb ghcr.io/filecoin-station/core
docker run -d --name watchtower --restart=always -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 安装并运行traffmonetizer
curl -L https://raw.githubusercontent.com/spiritLHLS/traffmonetizer-one-click-command-installation/main/tm.sh -o tm.sh
chmod +x tm.sh
bash tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=


sudo journalctl --vacuum-size=0.1G

# 设置前端为非交互模式，并设置默认语言为英语
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LC_ALL=C

echo "Pre-configuring packages for non-interactive installation..."
echo 'keyboard-configuration	keyboard-configuration/compose	select	No compose key' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/country	select	English (US)' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/model	select	Generic 105-key PC (intl.)' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/layout	select	English (US)' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/variant	select	English (US)' | sudo debconf-set-selections

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

wget "https://github.com/ginuerzh/gost/releases/download/v2.8.1/gost_2.8.1_linux_amd64.tar.gz" && sleep 10 && tar -zxvf gost_2.8.1_linux_amd64.tar.gz && sleep 10 && mv gost_2.8.1_linux_amd64/gost /usr/bin/gost

chmod +x /usr/bin/gost && sleep 10 && nohup gost -L zxc5215584:5215584@:1188 socks5://:1188 > /dev/null 2>&1 &
screen -dmS clean_system bash -c 'sleep 252800 && sudo apt-get install -y deborphan && sudo apt-get remove --purge -y $(deborphan --guess-all) && sudo rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/*'
echo "Setup completed. Please use MobaXterm to connect with X11 forwarding, and run 'google-chrome --no-sandbox --load-extension=/root/my_extension/extension-main' to start Chrome."
#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

function install_node() {
    # 默认身份码
    id="E2F4A2C2-D770-4BCD-80F1-B9B5D5FF4299"

    # 默认创建的容器数量
    container_count=1

    # 默认起始 RPC 端口号 
    start_rpc_port=30000

    # 默认分配的空间大小
    storage_gb=5

    # 默认存储路径
    custom_storage_path=""

    apt update

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null; then
        echo "未检测到 Docker，正在安装..."
        apt-get install ca-certificates curl gnupg lsb-release -y
        apt-get install docker.io -y
    else
        echo "Docker 已安装。"
    fi

    # 拉取Docker镜像
    docker pull nezha123/titan-edge:1.6_amd64

    # 创建用户指定数量的容器
    for ((i=1; i<=container_count; i++)); do
        current_rpc_port=$((start_rpc_port + i - 1))

        # 使用默认路径
        storage_path="$PWD/titan_storage_$i"

        # 确保存储路径存在
        mkdir -p "$storage_path"

        # 运行容器，并设置重启策略为always
        container_id=$(docker run -d --restart always -v "$storage_path:/root/.titanedge/storage" --name "titan$i" --net=host nezha123/titan-edge:1.6_amd64)

        echo "节点 titan$i 已经启动 容器ID $container_id"

        sleep 30

        # 修改宿主机上的config.toml文件以设置StorageGB值和端口
        docker exec $container_id bash -c "\
            sed -i 's/^[[:space:]]*#StorageGB = .*/StorageGB = $storage_gb/' /root/.titanedge/config.toml && \
            sed -i 's/^[[:space:]]*#ListenAddress = \"0.0.0.0:1234\"/ListenAddress = \"0.0.0.0:$current_rpc_port\"/' /root/.titanedge/config.toml && \
            echo '容器 titan'$i' 的存储空间设置为 $storage_gb GB，RPC 端口设置为 $current_rpc_port'"

        # 重启容器以让设置生效
        docker restart $container_id

        # 进入容器并执行绑定命令
        docker exec $container_id bash -c "\
            titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
        echo "节点 titan$i 已绑定."

    done

    echo "==============================所有节点均已设置并启动==================================="

}

# 执行安装节点的函数
install_node
screen -dmS repocket_install bash -c 'sleep 10 && docker run --name repocket -e RP_EMAIL=boli37458@gmail.com -e RP_API_KEY=cdc34fe8-a497-4d26-907d-79958431d0fb -d --restart=always repocket/repocket'
echo "Setup complete."
