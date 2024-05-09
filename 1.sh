#!/bin/bash

LOG_FILE=withdraw_rewards.log
NODE_COUNT=20
BASE_PORT=1317
WITHDRAW_ADDRESS="0xdfF37251694167f6cb95D6CdB7Fa70cb56eb62C3" # 替换为你的提取地址

echo "-----------------------" >> $LOG_FILE
echo "Withdrawal Run at $(date)" >> $LOG_FILE

for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PORT=$((BASE_PORT + i))
    PRIV_KEY_FILE=$NODE_DIR/privkey.json

    # 查询余额
    RESPONSE=$(./aioznode reward balance --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
    BALANCE=$(echo "$RESPONSE" | jq -r '.balance // "0"')

    # 1 aiozcoin = 1000000000000000000 wei
    # 将余额转换为aioz并四舍五入到最接近的小数点后一位
    BALANCE_AIOZ=$(echo "scale=1; $BALANCE/1000000000000000000" | bc)

    if (( $(echo "$BALANCE_AIOZ > 0.05" | bc -l) )); then
        # 提取余额
        WITHDRAWAL_AMOUNT=$(echo "$BALANCE_AIOZ/1" | bc) # 整数部分
        WITHDRAW_RESPONSE=$(./aioznode reward withdraw --address $WITHDRAW_ADDRESS --amount ${WITHDRAWAL_AMOUNT}.0aioz --priv-key-file $PRIV_KEY_FILE --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)
        
        # 验证提取是否成功
        if [[ "$WITHDRAW_RESPONSE" == *"success"* ]]; then
            echo "Successful withdrawal for node $i: $BALANCE_AIOZ aioz" >> $LOG_FILE
        else
            echo "Withdrawal failed for node $i, received response: $WITHDRAW_RESPONSE" >> $LOG_FILE
        fi
    else
        echo "Not enough balance to withdraw for node $i, balance is $BALANCE_AIOZ aioz" >> $LOG_FILE
    fi
done
