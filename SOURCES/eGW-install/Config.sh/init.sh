#!/bin/bash -
#########################################################################################
# init.sh
# version:6.0
# update:20210805
#########################################################################################

function init_dir() {
    for dir in Record history keepalived redis nginx ltegwd sctpd tcpdump vtysh vtyhistory watchdog \
	omcapi/manage omcapi/monitor omcapi/report omcapi/alarm \
        oam_trace/tr069 oam_trace/ftp-func oam_trace/post-office
    do
        [[ ! -d $LOG_DIR/$dir ]] && mkdir -p $LOG_DIR/$dir
    done
}

function init_net() {
    modprobe 8021q
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
    local default_password="WCG@baicells.com"
    sed -i "s/^appendonly yes/appendonly no/" $REDIS_CONF
    grep -q "^requirepass" $REDIS_CONF || sed -i "/# Command renaming./i requirepass $default_password" $REDIS_CONF
    grep -q "^masterauth" $REDIS_CONF || sed -i "/# When a slave loses/i masterauth $default_password" $REDIS_CONF
    export redisHost="127.0.0.1"
    export redisPort="9736"
    export redisPass=$(cat $REDIS_CONF|awk '/^requirepass/{print $2}')
    export redisShort="redis-cli -h $redisHost -p $redisPort -a ${redisPass:-\"\"}"
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' $HA_CONF)
    local ha_local=$(awk -F ' = ' '/^localip/{print $2}' $HA_CONF)
    if [[ $ha_switch == "enable" ]];then
        if [[ $ha_local ]];then
            grep "^bind $redisHost $ha_local" $REDIS_CONF
            if [[ $? == 1 ]];then
                sed -i "s@^bind .*@bind $redisHost $ha_local@g" $REDIS_CONF
                #systemctl restart redis_wcg
            fi
        fi
    else
        grep "^bind $redisHost" $REDIS_CONF
        if [[ $? == 1 ]];then
            sed -i "s@^bind .*@bind ${redisHost}@g" $REDIS_CONF
        fi
    fi
    systemctl restart redis_wcg
    while :
    do
        local redis_wcg_status=$($redisShort ping)
        if [[ $redis_wcg_status == "PONG" ]];then
            break
        fi
    done
    $redisShort del eGWActiveEnb &>/dev/null
    $redisShort del eGWConnectedUe &>/dev/null
    $redisShort bgrewriteaof
}

function init_nginx() {
    for dir in conf.d default.d
    do
        [[ ! -d $NGINX_CONF_DIR/$dir ]] && mkdir -p $NGINX_CONF_DIR/$dir
    done
    systemctl restart nginx_wcg
}

function init_para() {
    if [[ -f $PARA_CONF ]];then
        $redisShort del eGW-para-default
        while read line
        do
            if [[ "${line:0:1}" != "#" ]]; then
                [[ -z "$line" ]] && continue
                key=$(echo $line | awk '{print $1}')
                value=$(echo $line | awk '{print $3}')
                $redisShort hset eGW-para-default $key $value
            fi	
        done < $PARA_CONF
    fi
}

function read_para() {
    IPSEC_UPLINK_DEFAULT=$($redisShort hget eGW-para-default config_ipsec_uplink_switch)
    IPSEC_UPLINK_SET=$($redisShort hget eGW-para-set config_ipsec_uplink_switch)
    IPSEC_DOWNLINK_DEFAULT=$($redisShort hget eGW-para-default config_ipsec_downlink_switch)
    IPSEC_DOWNLINK_SET=$($redisShort hget eGW-para-set config_ipsec_downlink_switch)
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

function init() {
    init_dir
    init_net
    init_redis
    init_nginx
    init_para
    read_para
    start_ipsec
}

