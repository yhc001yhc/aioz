#!/bin/bash

LOG_FILE=query_balance.log
NODE_COUNT=30
BASE_PORT=1317

echo "-----------------------" >> $LOG_FILE
echo "Query Run at $(date)" >> $LOG_FILE

for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PORT=$((BASE_PORT + i))
    
    # 假设这里是创建节点的命令，您需要根据实际命令进行调整，这里仅作为示范
    # echo "Creating node $i at $(date)" >> $LOG_FILE
    # ./create_node_command --home $NODE_DIR --port $PORT
    
    # 查询余额，确保使用正确的端点
    RESPONSE=$(./aioznode reward balance --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
    BALANCE=$(echo "$RESPONSE" | jq -r '.balance // empty')
    
    # 如果jq提取的值是数字，它会记录余额，否则报告可能的空或者null值。
    if [[ $BALANCE =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Node $i: Current balance is $BALANCE" >> $LOG_FILE
    else
        echo "Error or no balance available for node $i, received response: $RESPONSE" >> $LOG_FILE
    fi

    # 如果不是最后一个节点，则暂停60秒（1分钟）
    if (( i < NODE_COUNT )); then
        sleep 60
    fi
done
