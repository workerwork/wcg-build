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
            sleep_timer_default=$($redisShort hget eGW-para-default $timer)
            sleep_timer_set=$($redisShort hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            if [[ $sleep_timer != "0"  ]];then
                $task && sleep ${sleep_timer:-"60"} || exit 1
            else
                sleep 5
            fi
        else
            sleep_timer_default=$($redisShort hget eGW-para-default $timer)
            sleep_timer_set=$($redisShort hget eGW-para-set $timer)
            sleep_timer=${sleep_timer_set:-$sleep_timer_default}
            keep_num_default=$($redisShort hget eGW-para-default $num)
            keep_num_set=$($redisShort hget eGW-para-set $num)
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

function del_log() {
    log_path=$1
    log_num=$2
    ls -lt $log_path 2>/dev/null | awk -v log_num=$log_num '{if(NR>log_num){print $9}}' | xargs rm -rf
}

function ps_log() {
    del_log "$WATCHDOG_LOG_DIR/ps*.log" $1
}

function history_log() {
    del_log "$LOG_DIR/history/*.log" $1
}

function keepalived_log() {
    del_log "$LOG_DIR/keepalived/*.log" $1
}

function ltegwd_log() {
    del_log "$LOG_DIR/ltegwd/egw.log_*" $1
}

function sctpd_log() {
    del_log "$LOG_DIR/sctpd/sctpd.log_*" $1
}

function manage_log() {
    del_log "$LOG_DIR/omcapi/manage/egw_manage.log_*" $1
}

function report_log() {
    del_log "$LOG_DIR/omcapi/report/egw_report.log_*" $1
}

function monitor_log() {
    del_log "$LOG_DIR/omcapi/monitor/egw_monitor.log_*" $1
}

function vtysh_log() {
    del_log "$LOG_DIR/vtysh/vtysh.log_*" $1
}

function core_log() {
    del_log "/root/coredump/core-ltegwd-*" $1
}

function crash_log() {
    del_log "/var/crash/*" $1
}
