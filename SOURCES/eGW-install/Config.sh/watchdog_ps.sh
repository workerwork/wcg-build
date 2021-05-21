#!/bin/bash -
#########################################################################################
# watchdog_ps.sh
# version:5.0
# update:20210520
#########################################################################################
function watch_ps() {
    task=$1
    timer=$2
    while :
    do
        sleep_timer_default=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-default $timer)
        sleep_timer_set=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-set $timer)
        sleep_timer=${sleep_timer_set:-$sleep_timer_default}
        if [[ $sleep_timer == 0  ]];then
            sleep 5
        else
            $task && sleep ${sleep_timer:-"5"} || exit 1
        fi
    done
}

[[ $1 ]] && watch_ps $1 $2

function ps_ltegwd() {
    local count=$(ps -ef |grep ${exec_ltegwd}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]] && [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then       
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: ltegwd restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-ltegwd 1
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps ltegwd:1
	start_ltegwd 
    else		
        ltegwd_state=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-status eGW-ps-state-ltegwd)
        if [[ $ltegwd_state == 1 ]];then
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps ltegwd:0
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-ltegwd 0
        fi
    fi
}

function ps_gwrec() {
    local count=$(ps -ef |grep ${exec_gwrec}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]] && [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: gwrec restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        start_gwrec
    fi
}

function ps_sctpd() {
    local count=$(ps -ef |grep ${exec_sctpd}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]] && [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: sctpd restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        pkill ltegwd
        start_gtp_ko
        redis-cli -h 127.0.0.1 -p 9736 -a "redisPass" del eGWActiveEnb
        redis-cli -h 127.0.0.1 -p 9736 -a "redisPass" del eGWConnectedUe
        start_ltegwd	
        start_sctpd
    fi
}

function ps_egw_manage() {
    local count=$(ps -ef |grep ${exec_egw_manage}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_manage restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
   	redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_manage 1
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_manage:1
        start_egw_manage
    else
        egw_manage_state=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-status eGW-ps-state-egw_manage)
        if [[ $egw_manage_state == 1 ]];then
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_manage:0
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_manage 0
        fi
    fi
}

function ps_egw_report() {
    local count=$(ps -ef |grep ${exec_egw_report}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_report restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_report 1
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_report:1
        start_egw_report
    else
        egw_report_state=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-status eGW-ps-state-egw_report)
        if [[ $egw_report_state == 1 ]];then
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_report:0
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_report 0
        fi
    fi
}

function ps_egw_monitor() {
    local count=$(ps -ef |grep ${exec_egw_monitor}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_monitor restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_monitor 1
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_monitor:1
        start_egw_monitor
    else
        egw_monitor_state=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-status eGW-ps-state-egw_monitor)
        if [[ $egw_monitor_state == 1 ]];then
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_monitor:0
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_monitor 0
        fi
    fi
}

function ps_egw_manage_logger() {
    local count=$(ps -ef |grep ${exec_egw_manage_logger}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_manage_logger restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_manage_logger 1
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_manage_logger:1
        start_egw_manage_logger
    else
        egw_manage_logger_state=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-status eGW-ps-state-egw_manage_logger)
        if [[ $egw_manage_logger_state == 1 ]];then
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps egw_manage_logger:0
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-egw_manage_logger 0
        fi
    fi
}


function ps_kpiMain() {
    local count=$(ps -ef |grep ${exec_kpiMain}$|grep -v 'grep'|wc -l)
    if [[ $count != 1 ]];then
        $TOOLS_DIR/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: kpiMain restart" >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-kpiMain 1
        redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps kpiMain:1
        start_KPIMain
    else
        kpiMain_state=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-status eGW-ps-state-kpiMain)
        if [[ $kpiMain_state == 1 ]];then
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" lpush eGW-alarm-ps kpiMain:0
            redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hset eGW-status eGW-ps-state-kpiMain 0
        fi
    fi
}

