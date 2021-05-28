#!/bin/bash -
#########################################################################################
# keepalived.sh
# version:5.0
# update:20210520
##########################################################################################
LOG_PATH="$LOG_DIR/keepalived"
HA_STATUS="/root/eGW/.ha.status"
NOTIFY=$1

function keepalived() {
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' $HA_CONF)
    if [[ $ha_switch == "enable" ]];then
        systemctl enable keepalived_wcg
        systemctl start keepalived_wcg
        if [[ ! -f $HA_STATUS ]];then
            echo "MASTER" > $HA_STATUS
        fi
        local ha_status=$(cat $HA_STATUS)
        if [[ $ha_status == "MASTER" ]];then
            $redisShort slaveof no one
            echo "local server is master,go on!"    
        elif [[ $ha_status == "BACKUP" ]];then
            local ha_slave=$(awk -F ' = ' '/^slaveip/{print $2}' $HA_CONF)
            $redisShort slaveof $ha_slave $redisPort
            [[ $(ipsec status) ]] && ipsec stop
            echo "local server is backup,exit!"
            exit 0
        else
            echo "local server is fault or stop,exit!"
            exit 0
        fi
    else
        systemctl disable keepalived_wcg
        systemctl stop keepalived_wcg
    fi
}

function keepalived_log() {
    time_all=$(date +%Y-%m-%d' '%H:%M:%S)
    time_Ymd=$(date +%Y%m%d)
    echo $time_all " keepalived: local server change to $1, $2 monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_master() {
    echo "MASTER" > $HA_STATUS
    systemctl restart monitor
    keepalived_log "master" "start"
}

function to_backup() {
    echo "BACKUP" > $HA_STATUS
    systemctl restart monitor
    keepalived_log "backup" "stop"
}

function to_fault() {
    echo "FAULT" > $HA_STATUS
    systemctl restart monitor
    keepalived_log "fault" "stop"
}

function to_stop() {
    echo "STOP" > $HA_STATUS
    systemctl restart monitor
    keepalived_log "stop" "stop"
}

function notify() {
    case $NOTIFY in
        "master")
        to_master
        ;;
        "backup")
        to_backup
        ;;
        "fault")
        to_fault
        ;;
        "stop")
        to_stop
        ;;
    esac
}

notify
