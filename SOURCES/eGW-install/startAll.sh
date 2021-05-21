#!/bin/bash -
#########################################################################################
# startAll.sh
# version:5.0
# update:20210520
#########################################################################################
#[ /root/eGW/Config.sh/parameters.conf ] && source /root/eGW/Config.sh/parameters.conf

#------------------------------
export BASE_DIR="/root/eGW"
export CUR_DIR="$BASE_DIR/Config.sh"
export LOG_DIR="$BASE_DIR/Logs"
export WATCHDOG_LOG_DIR="$LOG_DIR/watchdog"
export REDIS_DIR="$BASE_DIR/redis"
export REDIS_CONF="$REDIS_DIR/redis_wcg.conf"
export redisPass=$(cat $REDIS_CONF | awk '/^requirepass/{print $2}')
export NGINX_DIR="$BASE_DIR/nginx"
export OMC_DIR="$BASE_DIR/OMC"
export TOOLS_DIR="$BASE_DIR/Tools"
export NET_CONF="$BASE_DIR/networkcfg.conf"
export PARA_CONF="$BASE_DIR/.para.init"
export HA_CONF="$BASE_DIR/ha.conf"
export HA_STATUS="$BASE_DIR/.ha.status"
export GTP_KO="$BASE_DIR/gtp-relay.ko"
export GOTTY_CONF="$BASE_DIR/gotty.conf"
export GOTTY="$BASE_DIR/gotty"
export VTYSH="$BASE_DIR/vtysh"
#-------------------------------

#init the redis nginx ipsec
source $CUR_DIR/init.sh && init
#sleep 2

#configure iptables
#source $CUR_DIR/iptables.sh && config_iptables

#start gwrec
#source $CUR_DIR/watchdog.sh && watchdog_gwrec &

#configure keepalived
source $CUR_DIR/keepalived.sh && keepalived

#start process
source $CUR_DIR/process.sh && process
export -f start_ltegwd
export -f start_sctpd
export -f start_gwrec
export -f start_egw_manage
export -f start_egw_manage_logger
export -f start_egw_report
export -f start_egw_monitor
export -f start_KPIMain
sleep 1

#configure eGW
#source $CUR_DIR/egw.sh && egw 

#start watchdog
source $CUR_DIR/watchdog.sh && watchdog &

