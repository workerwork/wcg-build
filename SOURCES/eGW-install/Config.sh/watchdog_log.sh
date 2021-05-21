#!/bin/bash -
#########################################################################################
# watchdog_log.sh
# version:5.0
# update:20210520
#########################################################################################
function watch_log() {
    task=$1
    timer=$2
    num=$3
    while :
    do
        if [[ $num == "&" ]];then
            sleep_timer_default=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-default $timer)
            sleep_timer_set=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            if [[ $sleep_timer != "0"  ]];then
                $task && sleep ${sleep_timer:-"60"} || exit 1
            else
                sleep 5
            fi
        else
            sleep_timer_default=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-default $timer)
            sleep_timer_set=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            keep_num_default=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-default $num)
            keep_num_set=$(redis-cli -h 127.0.0.1 -p 9736 -a "$redisPass" hget eGW-para-set $num)
            keep_num=${keep_num_set:-$keep_num_default}
            if [[ $sleep_timer != "0"  ]];then
                $task ${keep_num:-"15"} && sleep ${sleep_timer:-"60"} || exit 1
            else
                sleep 5
            fi
        fi
    done
}

[[ $1 ]] && watch_log $1 $2 $3

function ps_log() {
    ps_num=$1
    ls -lt $WATCHDOG_LOG_DIR/ps*.log 2>/dev/null | awk -v ps_num=$ps_num '{if(NR>ps_num){print $9}}' | xargs rm -rf
}

function history_log() {
    history_num=$1
    ls -lt $LOG_DIR/history/*.log 2>/dev/null | awk -v history_num=$history_num '{if(NR>history_num){print $9}}' | xargs rm -rf
}

function keepalived_log() {
    keepalived_num=$1
    ls -lt $LOG_DIR/keepalived/*.log 2>/dev/null | awk -v keepalived_num=$keepalived_num '{if(NR>keepalived_num){print $9}}' | xargs rm -rf
}

function ltegwd_log() {
    ltegwd_num=$1
    ls -lt $LOG_DIR/ltegwd/egw.log_* 2>/dev/null | awk -v ltegwd_num=$ltegwd_num '{if(NR>ltegwd_num){print $9}}' | xargs rm -rf	
}

function sctpd_log() {
    sctpd_num=$1
    ls -lt $LOG_DIR/sctpd/sctpd.log_* 2>/dev/null | awk -v sctpd_num=$sctpd_num '{if(NR>sctpd_num){print $9}}' | xargs rm -rf	
}

function manage_log() {
    manage_num=$1
    ls -lt $LOG_DIR/omcapi/manage/egw_manage.log_* 2>/dev/null | awk -v manage_num=$manage_num '{if(NR>manage_num){print $9}}' | xargs rm -rf
}

function report_log() {
    report_num=$1
    ls -lt $LOG_DIR/omcapi/report/egw_report.log_* 2>/dev/null | awk -v report_num=$report_num '{if(NR>report_num){print $9}}' | xargs rm -rf
}

function monitor_log() {
    monitor_num=$1
    ls -lt $LOG_DIR/omcapi/monitor/egw_monitor.log_* 2>/dev/null | awk -v monitor_num=$monitor_num '{if(NR>monitor_num){print $9}}' | xargs rm -rf
}

function vtysh_log() {
    vtysh_num=$1
    ls -lt $LOG_DIR/vtysh/vtysh.log_* 2>/dev/null | awk -v vtysh_num=$vtysh_num '{if(NR>vtysh_num){print $9}}' | xargs rm -rf
}

