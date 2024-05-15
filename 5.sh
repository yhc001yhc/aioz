#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 自动设置的值
id="C3E62B98-2F0A-4C4D-8C61-DDAC5861805D" # 身份码
container_count=5 # 节点数量
disk_size_gb=2 # 每个节点的硬盘大小
volume_dir="/root/docker_volumes" # 数据卷存放目录

apt update

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    echo "未检测到 Docker，正在安装..."
    apt-get install docker.io -y
else
    echo "Docker 已安装。"
fi

# 拉取Docker镜像
docker pull nezha123/titan-edge

# 创建映像文件存放目录
mkdir -p "$volume_dir"

# 创建用户指定数量的容器
for i in $(seq 1 $container_count)
do
    disk_size_mb=$((disk_size_gb * 1024))
    volume_path="$volume_dir/volume_$i.img"
    sudo dd if=/dev/zero of="$volume_path" bs=1M count=$disk_size_mb
    sudo mkfs.ext4 "$volume_path"

    mount_point="/mnt/my_volume_$i"
    mkdir -p "$mount_point"
    sudo mount -o loop "$volume_path" "$mount_point"

    echo "$volume_path $mount_point ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab

    # 运行容器，并设置重启策略为always
    container_id=$(docker run -d --restart always -v $mount_point:/root/.titanedge/storage --name "titan$i" -p $((3000+i-1)):2888 nezha123/titan-edge)

    echo "节点 titan$i 已经启动"

    sleep 30

    # 绑定节点
    docker exec -it "titan$i" bash -c "titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
done

echo "==============================所有节点均已设置并启动==================================="
