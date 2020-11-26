#!/bin/bash -
#########################################################################################
# keepalived.sh
# version:4.1
# update:20181023
##########################################################################################
redisPass=`cat /root/eGW/redis/redis_wcg.conf | awk '/^requirepass/{print $2}'`
LOG_PATH=/root/eGW/Logs/keepalived
NOTIFY=$1

function keepalived() {
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' /root/eGW/ha.conf)
    if [[ $ha_switch == "enable" ]];then
        systemctl enable keepalived_wcg
        systemctl start keepalived_wcg
        if [[ ! -f /root/eGW/.ha.status ]];then
            echo "MASTER" > /root/eGW/.ha.status
        fi
        local ha_status=$(cat /root/eGW/.ha.status)
        if [[ $ha_status == "MASTER" ]];then
			if [[ $redisPass ]]; then
					redis-cli -h 127.0.0.1 -p 9736 -a $redisPass slaveof no one
			else
					redis-cli -h 127.0.0.1 -p 9736 slaveof no one
			fi
            echo "local server is master,go on!"    
        elif [[ $ha_status == "BACKUP" ]];then
            local ha_slave=$(awk -F ' = ' '/^slaveip/{print $2}' /root/eGW/ha.conf)
			if [[ $redisPass ]]; then
            		redis-cli -h 127.0.0.1 -p 9736 -a $redisPass slaveof $ha_slave 9736
			else
          		  	redis-cli -h 127.0.0.1 -p 9736 slaveof $ha_slave 9736
			fi
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
    echo "MASTER" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to master,start monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_backup() {
    echo "BACKUP" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to backup,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_fault() {
    echo "FAULT" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to fault,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
}

function to_stop() {
    echo "STOP" > /root/eGW/.ha.status
    systemctl restart monitor
    time_all=`date +%Y-%m-%d' '%H:%M:%S`
    time_Ymd=`date +%Y%m%d`
    echo $time_all " keepalived: local server change to stop,stop monitor" >> $LOG_PATH/keepalived_${time_Ymd}.log
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
