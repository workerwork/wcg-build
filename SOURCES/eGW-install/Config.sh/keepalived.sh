#!/bin/bash -
#########################################################################################
# keepalived.sh
# version:5.0
# update:20210520
##########################################################################################
LOG_PATH="$LOG_DIR/keepalived"

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
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" slaveof no one
            echo "local server is master,go on!"    
        elif [[ $ha_status == "BACKUP" ]];then
            local ha_slave=$(awk -F ' = ' '/^slaveip/{print $2}' $HA_CONF)
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" slaveof $ha_slave 9736
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

function to_master() {
    echo "MASTER" > $HA_STATUS
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to master,start monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_backup() {
    echo "BACKUP" > $HA_STATUS
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to backup,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_fault() {
    echo "FAULT" > $HA_STATUS
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to fault,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_stop() {
    echo "STOP" > $HA_STATUS
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to stop,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function notify() {
    case $1 in
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
