#!/bin/bash

LOG_FILE="combined_operations.log"
NODE_COUNT=20
WITHDRAW_ADDRESS="0xdfF37251694167f6cb95D6CdB7Fa70cb56eb62C3" # 替换为你的提取地址
BASE_PORT=1317

echo "-----------------------" >> $LOG_FILE
echo "Operations Run at $(date)" >> $LOG_FILE

for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PORT=$((BASE_PORT + i))

    # 查询余额
    RESPONSE=$(./aioznode reward balance --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
    BALANCE=$(echo "$RESPONSE" | jq -r '.balance[] // "0"')
    WITHDRAW=$(echo "$RESPONSE" | jq -r '.withdraw[] // "0"')

    # 由于BALANCE和WITHDRAW是以基本单位返回，我们需要将它们转换并计算最终余额
    FINAL_BALANCE_AIOZ=$(echo "$BALANCE - $WITHDRAW" | bc)
    FINAL_BALANCE_AIOZ=$(echo "scale=18; $FINAL_BALANCE_AIOZ / 1000000000000000000" | bc)

    echo "Node $i: Calculated final balance is $FINAL_BALANCE_AIOZ AIOZ" >> $LOG_FILE
    
    # 检查是否有余额可提取
    if (( $(echo "$FINAL_BALANCE_AIOZ > 0.0" | bc -l) )); then
        WITHDRAW_RESPONSE=$(./aioznode reward withdraw --address $WITHDRAW_ADDRESS --amount ${FINAL_BALANCE_AIOZ}aioz --priv-key-file $NODE_DIR/privkey.json --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
        
        # 验证提取是否成功
        if [[ "$WITHDRAW_RESPONSE" == *"success"* ]]; then
            echo "Successful: Withdraw of $FINAL_BALANCE_AIOZ AIOZ for node $i" >> $LOG_FILE
        else
            echo "Failed: Withdraw attempt for node $i, response: $WITHDRAW_RESPONSE" >> $LOG_FILE
        fi
    else
        echo "No balance to withdraw for node $i after accounting for withdraws." >> $LOG_FILE
    fi
done
