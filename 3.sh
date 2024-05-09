#!/bin/bash

LOG_FILE=query_balance.log
NODE_COUNT=10
BASE_PORT=1317

echo "-----------------------" >> $LOG_FILE
echo "Query Run at $(date)" >> $LOG_FILE

for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PORT=$((BASE_PORT + i))

    # 查询余额，确保使用正确的端点
    RESPONSE=$(./aioznode reward balance --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
    BALANCE=$(echo "$RESPONSE" | jq -r '.balance // empty')
    
    # 如果jq提取的值是数字，它会记录余额，否则报告可能的空或者null值。
    if [[ $BALANCE =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Node $i: Current balance is $BALANCE" >> $LOG_FILE
    else
        echo "Error or no balance available for node $i, received response: $RESPONSE" >> $LOG_FILE
    fi
done
