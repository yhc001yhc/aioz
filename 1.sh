#!/bin/bash

NODE_COUNT=40
WITHDRAW_ADDRESS="0xdfF37251694167f6cb95D6CdB7Fa70cb56eb62C3"
BASE_PORT=1317
LOG_FILE="/root/withdraw.log"

echo "-----------------------" >> "$LOG_FILE"
echo "Withdraw Run at $(date)" >> "$LOG_FILE"

for ((i=1; i<=NODE_COUNT; i++)); do
    NODE_DIR="/root/nodes/node-$i"
    PORT=$((BASE_PORT + i))
    ENDPOINT="http://127.0.0.1:$PORT"
    PRIV_KEY_FILE="$NODE_DIR/privkey.json"

    RESPONSE=$(./aioznode reward balance --home "$NODE_DIR" --endpoint "$ENDPOINT")
    BALANCE=$(echo "$RESPONSE" | jq -r '.balance[0].amount // "0"')

    if [ "$BALANCE" -gt 0 ]; then
        FINAL_BALANCE_AIOZ=$(echo "scale=18; $BALANCE / 1000000000000000000" | bc | awk '{printf "%.18f\n", $0}')
        WITHDRAW_RESPONSE=$(./aioznode reward withdraw --address "$WITHDRAW_ADDRESS" --amount "${FINAL_BALANCE_AIOZ}aioz" --priv-key-file "$PRIV_KEY_FILE" --home "$NODE_DIR" --endpoint "$ENDPOINT")
        echo "$WITHDRAW_RESPONSE" >> "$LOG_FILE"
    else
        echo "Node $i: No balance to withdraw." >> "$LOG_FILE"
    fi
    
    if [ $i -lt $NODE_COUNT ]; then
        sleep 3900
    fi
done
