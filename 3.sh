#!/bin/bash

LOG_FILE=query_balance.log
NODE_COUNT=30
BASE_PORT=1317
CONVERSION_RATE=1000000000000000000 # 1 AIOZ = 10^18 attoaioz
RMB_CONVERSION=7.25 # RMB 兑换率

echo "-----------------------" >> $LOG_FILE
echo "Query Run at $(date)" >> $LOG_FILE

TOTAL_REMAINING=0
TOTAL_WITHDRAWN=0

# 遍历所有节点
for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PORT=$((BASE_PORT + i))

    # 查询余额，确保使用正确的端点
    RESPONSE=$(./aioznode reward balance --home $NODE_DIR --endpoint http://127.0.0.1:$PORT)

    # 记录原始响应
    echo "Node $i: $RESPONSE" >> $LOG_FILE

    # 提取未提取总量和已提取总量
    REMAINING_AMOUNT=$(echo "$RESPONSE" | jq -r '.balance[0].amount // "0"')
    WITHDRAWN_AMOUNT=$(echo "$RESPONSE" | jq -r '.withdraw[0].amount // "0"')

    # 换算至 AIOZ 单位
    REMAINING_UNIT=$(echo "scale=18; $REMAINING_AMOUNT / $CONVERSION_RATE" | bc)
    WITHDRAWN_UNIT=$(echo "scale=18; $WITHDRAWN_AMOUNT / $CONVERSION_RATE" | bc)

    # 确保数值非空
    REMAINING_UNIT=${REMAINING_UNIT:-0}
    WITHDRAWN_UNIT=${WITHDRAWN_UNIT:-0}

    # 汇总剩余和已提取的总量
    TOTAL_REMAINING=$(echo "$TOTAL_REMAINING + $REMAINING_UNIT" | bc)
    TOTAL_WITHDRAWN=$(echo "$TOTAL_WITHDRAWN + $WITHDRAWN_UNIT" | bc)

    # 记录格式化的余额信息
    echo "Node $i: Remaining balance (formatted): $REMAINING_UNIT AIOZ, Withdrawn balance (formatted): $WITHDRAWN_UNIT AIOZ" >> $LOG_FILE
done

# 格式化总的剩余和提取余额
TOTAL_REMAINING=$(echo "scale=4; $TOTAL_REMAINING" | bc | awk '{printf "%.4f\n", $0}')
TOTAL_WITHDRAWN=$(echo "scale=4; $TOTAL_WITHDRAWN" | bc | awk '{printf "%.4f\n", $0}')

# 输出汇总结果
echo "-----------------------" >> $LOG_FILE
echo "Total Remaining Balance: $TOTAL_REMAINING AIOZ" >> $LOG_FILE
echo "Total Withdrawn Balance: $TOTAL_WITHDRAWN AIOZ" >> $LOG_FILE

# 换算已提取余额为人民币价值
WITHDRAWN_RMB=$(echo "scale=2; $TOTAL_WITHDRAWN * 0.75 * $RMB_CONVERSION" | bc)
echo "Withdrawn Balance Value in RMB: $WITHDRAWN_RMB RMB" >> $LOG_FILE

echo "All results have been logged into $LOG_FILE."
