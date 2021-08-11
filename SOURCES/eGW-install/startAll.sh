#!/bin/bash -
#########################################################################################
# startAll.sh
# version:6.0
# update:20210805
#########################################################################################
#--------------------------------------------------------
export LIB_DIR="/usr/lib/eGW"
export LOG_DIR="/var/log/eGW"
export CFG_DIR="/etc/eGW"
export CUR_DIR="$LIB_DIR/Config.sh"
export WATCHDOG_LOG_DIR="$LOG_DIR/watchdog"
export REDIS_DIR="$LIB_DIR/redis"
export REDIS_CONF="$CFG_DIR/redis/redis_wcg.conf"
export NGINX_CONF_DIR="$CFG_DIR/nginx"
export OMC_DIR="$LIB_DIR/OMC"
export TOOLS_DIR="$LIB_DIR/Tools"
export NET_CONF="$CFG_DIR/networkcfg.conf"
export PARA_CONF="$LIB_DIR/.para.init"
export HA_CONF="$CFG_DIR/ha.conf"
export HA_STATUS="$LIB_DIR/.ha.status"
export GTP_KO="$LIB_DIR/gtp-relay.ko"
export GOTTY_CONF="$CFG_DIR/gotty.conf"
export GOTTY="$LIB_DIR/gotty"
export VTYSH="$LIB_DIR/vtysh"
export TR069_DIR="$LIB_DIR/TR069"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$TR069_DIR/lib"
#-------------------------------------------------------

#init the redis nginx ipsec
source $CUR_DIR/init.sh && init

#start process
source $CUR_DIR/process.sh && process_before_ha

#configure keepalived
source $CUR_DIR/keepalived.sh && keepalived

#start process
process_after_ha
sleep 1

#configure eGW
#source $CUR_DIR/egw.sh && egw 

#start watchdog
source $CUR_DIR/watchdog.sh && watchdog &

