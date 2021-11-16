#!/usr/bin/env bash

echo "show interface rate:"

while :
do
  eths=$1
  declare -A RXpreArray
  declare -A TXpreArray
  for eth in $eths
  do
    RXpreArray[$eth]=$(cat /proc/net/dev|grep $eth|tr : " "|awk '{print $2}')
    TXpreArray[$eth]=$(cat /proc/net/dev|grep $eth|tr : " "|awk '{print $10}')
  done
  sleep 1 && clear
  printf "%-30s%-30s%-30s\n" `date +%k:%M:%S` "RX" "TX"
  for eth in $eths
  do
    RXnext=$(cat /proc/net/dev|grep $eth|tr : " "|awk '{print $2}')
    TXnext=$(cat /proc/net/dev|grep $eth|tr : " "|awk '{print $10}')
    RX=$((RXnext-RXpreArray[$eth]))
    TX=$((TXnext-TXpreArray[$eth]))
    printf "%-30s%-30s%-30s\n" $eth $RX $TX
  done
done
