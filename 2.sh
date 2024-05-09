#!/bin/bash

NODE_COUNT=30
WITHDRAW_ADDRESS="0xdfF37251694167f6cb95D6CdB7Fa70cb56eb62C3"
AIOZ_NODE_URL="https://github.com/AIOZNetwork/aioz-dcdn-cli-node/files/13561211/aioznode-linux-amd64-1.1.0.tar.gz"

# 下载并解压 AIOZ Node
curl -LO $AIOZ_NODE_URL
tar xzf aioznode-linux-amd64-1.1.0.tar.gz
mv aioznode-linux-amd64-1.1.0 aioznode

# 创建节点文件夹
mkdir -p nodes

# 创建和启动节点
for i in $(seq 1 $NODE_COUNT); do
    # 每个节点的目录和私钥文件
    NODE_DIR=$(pwd)/nodes/node-$i
    PRIV_KEY_FILE=$NODE_DIR/privkey.json

    mkdir -p $NODE_DIR

    # 创建新的钱包并保存私钥
    ./aioznode/aioznode keytool new --home $NODE_DIR --save-priv-key $PRIV_KEY_FILE

    # 使用screen以独立会话启动每个节点
    screen -dmS aioznode-$i ./aioznode/aioznode start --home $NODE_DIR --priv-key-file $PRIV_KEY_FILE
done

