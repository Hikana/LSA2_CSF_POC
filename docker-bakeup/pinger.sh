#!/bin/sh

HOST="192.168.123.37"
COUNT=10

LOSS=$(ping -c $COUNT $HOST | grep -oP '\d+(?=% packet loss)')
echo "封包遺失率：$LOSS%"

if [ "$LOSS" -eq 100 ]; then
    ./restore.sh
fi