#!/bin/bash -
#########################################################################################
# init.sh
# version:5.0
# update:20210520
#########################################################################################

function init_dir() {
    for dir in history keepalived ltegwd sctpd tcpdump vtysh watchdog omcapi/manage omcapi/monitor omcapi/report
    do
        [[ ! -d $LOG_DIR/$dir ]] && mkdir -p $LOG_DIR/$dir
    done
}

function init_net() {
    if [[ -f $NET_CONF ]];then
        while read line
        do
            if [[ "${line:0:1}" != "#" ]]; then
                [[ -z "$line" ]] && continue
                $line 2>&1>/dev/null
            fi
        done < $NET_CONF
    fi
}

function init_redis() {
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' $HA_CONF)
    local ha_local=$(awk -F ' = ' '/^localip/{print $2}' $HA_CONF)
    if [[ $ha_switch == "enable" ]];then
        if [[ $ha_local ]];then
            grep "^bind 127.0.0.1 $ha_local" $REDIS_CONF
            if [[ $? == 1 ]];then
                sed -i "s@^bind .*@bind 127.0.0.1 $ha_local@g" $REDIS_CONF
                systemctl restart redis_wcg
            fi
        fi
    else
        grep "^bind 127.0.0.1" $REDIS_CONF
        if [[ $? == 1 ]];then
            sed -i "s@^bind .*@bind 127.0.0.1@g" $REDIS_CONF
            systemctl restart redis_wcg
        fi
    fi
    local redis_wcg_pid=$(ps -ef | grep redis-server | grep 9736 | awk '{print $2}')
    [[ $redis_wcg_pid ]] || systemctl restart redis_wcg
    while :
    do
        local redis_wcg_status=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" ping)
        if [[ $redis_wcg_status == "PONG" ]];then
            break
        fi
    done
    redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" bgrewriteaof	
}

function init_nginx() {
    for dir in conf.d default.d log
    do
        [[ ! -d $NGINX_DIR/$dir ]] && mkdir -p $NGINX_DIR/$dir
    done
    systemctl restart nginx_wcg
}

function init_para() {
    if [[ -f $PARA_CONF ]];then
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" del eGW-para-default
        while read line
        do
            if [[ "${line:0:1}" != "#" ]]; then
                [[ -z "$line" ]] && continue
                key=$(echo $line | awk '{print $1}')
                value=$(echo $line | awk '{print $3}')
                redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-para-default $key $value
            fi	
        done < $PARA_CONF
    fi
}

function read_para() {
    IPSEC_UPLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-default config_ipsec_uplink_switch)
    IPSEC_UPLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-set config_ipsec_uplink_switch)
    IPSEC_DOWNLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-default config_ipsec_downlink_switch)
    IPSEC_DOWNLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-set config_ipsec_downlink_switch)
}

function start_ipsec() {
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    local ipsec_downlink_default=${IPSEC_DOWNLINK_DEFAULT:-"disable"}
    local ipsec_downlink_set=${IPSEC_DOWNLINK_SET}
    local ipsec_downlink=${ipsec_downlink_set:-$ipsec_downlink_default}
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' $HA_CONF)
    if [[ ! -f $HA_STATUS ]];then
        echo "MASTER" > $HA_STATUS
    fi
    local ha_status=$(cat $HA_STATUS)
    if [[ $ha_switch == "enable" ]];then
        if [[ $ha_status == "MASTER" ]];then
            if [[ $ipsec_uplink == "enable" ]] || [[ $ipsec_downlink == "enable" ]];then
                ipsec start
            fi
        else
        	ipsec stop
        fi
    else
        if [[ $ipsec_uplink == "enable" ]] || [[ $ipsec_downlink == "enable" ]];then
            ipsec start
        fi
    fi
}

function init_gwrec() {
    if [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then
        $BASE_DIR/gwrec &
    else
        echo "can't start gwrec,exit!"
        exit 1
    fi
}

function init() {
    init_dir
    init_net
    init_redis
    init_nginx
    init_para
    read_para
    start_ipsec
    init_gwrec
}

