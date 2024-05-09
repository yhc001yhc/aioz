#!/bin/bash

NODE_COUNT=30
LOG_FILE=query_balance.log

echo "-----------------------" >> $LOG_FILE
echo "Query Run at $(date)" >> $LOG_FILE

for i in $(seq 1 $NODE_COUNT); do
    NODE_DIR=$(pwd)/nodes/node-$i
    PRIV_KEY_FILE=$NODE_DIR/privkey.json

    # 查询余额
    BALANCE=$(./aioznode reward balance --home $NODE_DIR | jq -r '.balance | select(.!=null) | tonumber')
    echo "Node $i: Current balance is $BALANCE" >> $LOG_FILE
done
