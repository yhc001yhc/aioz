#!/bin/bash

NODE_COUNT=20
LOG_FILE=withdraw_rewards.log
BASE_PORT=1317
WITHDRAW_ADDRESS="0xdfF37251694167f6cb95D6CdB7Fa70cb56eb62C3" # 确保替换为你的提取地址

echo "-----------------------" >> $LOG_FILE
echo "Withdrawal Run at $(date)" >> $LOG_FILE

for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PORT=$((BASE_PORT + i))
    PRIV_KEY_FILE=$NODE_DIR/privkey.json

    # 查询余额
    RESPONSE=$(./aioznode reward balance --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
    BALANCE=$(echo "$RESPONSE" | jq -r '.balance // empty')

    # 验证BALANCE是否为有效数字
    if [[ $BALANCE =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        # 提取余额
        WITHDRAW_RESPONSE=$(./aioznode reward withdraw --address $WITHDRAW_ADDRESS --amount ${BALANCE} --priv-key-file $PRIV_KEY_FILE --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)

        # 验证提取是否成功
        if [[ "$WITHDRAW_RESPONSE" == *"success"* ]]; then
            echo "Successful withdrawal for node $i: $BALANCE" >> $LOG_FILE
        else
            echo "Withdrawal failed for node $i, received response: $WITHDRAW_RESPONSE" >> $LOG_FILE
        fi
    else
        echo "No valid balance to withdraw for node $i or balance query failed, received response: $RESPONSE" >> $LOG_FILE
    fi
done
