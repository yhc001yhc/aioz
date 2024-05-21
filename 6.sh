#!/bin/bash

NODE_COUNT=30
BASE_PORT=1317
WITHDRAW_ADDRESS="0xdfF37251694167f6cb95D6CdB7Fa70cb56eb62C3"
AIOZ_NODE_URL="https://github.com/AIOZNetwork/aioz-dcdn-cli-node/files/13561211/aioznode-linux-amd64-1.1.0.tar.gz"

# 下载并解压 AIOZ Node
curl -LO $AIOZ_NODE_URL
tar xzf aioznode-linux-amd64-1.1.0.tar.gz
mv aioznode-linux-amd64-1.1.0 aioznode

# 确保aioznode是可执行的
chmod +x aioznode

# 创建节点文件夹
mkdir -p nodes

# 在后台为每个节点创建一个新的钱包并启动挖矿
for (( i=1; i<=NODE_COUNT; i++ )); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PRIV_KEY_FILE=$NODE_DIR/privkey.json
    PORT=$(($BASE_PORT + $i))

    mkdir -p $NODE_DIR
    
    # 创建新的钱包并保存私钥
    if ! ./aioznode keytool new --home $NODE_DIR --save-priv-key $PRIV_KEY_FILE; then
        echo "Failed to create wallet for node $i"
        continue
    fi

    # 使用screen以独立会话在后台启动每个节点
    screen -dmS aioznode-$i bash -c "./aioznode start --laddr tcp://0.0.0.0:$PORT --home $NODE_DIR --priv-key-file $PRIV_KEY_FILE; exec bash"
    
    echo "Node $i started on port $PORT in screen session aioznode-$i"

    # 每创造一个节点后暂停3分钟，除非是最后一个节点
    if [ $i -lt $NODE_COUNT ]; then
        sleep 600
    fi
done