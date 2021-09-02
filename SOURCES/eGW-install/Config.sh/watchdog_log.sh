#!/bin/bash -
#########################################################################################
# watchdog_log.sh
# version:6.0
# update:20210805
#########################################################################################
function watch_log() {
    task=$1
    timer=$2
    num=$3
    vol=$4
    ctime=$5
    while :
    do
        sleep_timer_default=$($redisShort hget eGW-para-default $timer)
        sleep_timer_set=$($redisShort hget eGW-para-set $timer)
        sleep_timer=${sleep_timer_set:-$sleep_timer_default}
        keep_num_default=$($redisShort hget eGW-para-default $num)
        keep_num_set=$($redisShort hget eGW-para-set $num)
        keep_num=${keep_num_set:-$keep_num_default}
        keep_vol_default=$($redisShort hget eGW-para-default $vol)
        keep_vol_set=$($redisShort hget eGW-para-set $vol)
        keep_vol=${keep_vol_set:-$keep_vol_default}
        keep_ctime_default=$($redisShort hget eGW-para-default $ctime)
        keep_ctime_set=$($redisShort hget eGW-para-set $ctime)
        keep_ctime=${keep_ctime_set:-$keep_ctime_default}
        if [[ $sleep_timer == "0"  ]];then
            sleep 60
        else
            $task ${keep_num:-"disable"} ${keep_vol:-"100"} ${keep_ctime:-"3600"} && sleep ${sleep_timer:-"60"} || exit 1
        fi
    done
}

[[ $1 ]] && watch_log $1 $2 $3 $4 $5

function del_log() {
    local log_path=$1
    local log_pattern=$2
    local log_num=$3
    local log_vol=$4
    local log_ctime=$5
    local log_name=$6
    local options=$7
    local log_time=$log_ctime
    # 单位 k
    local disk=$(du -s $log_path|awk '{print $1}')
    local state=$($redisShort hget eGW-status eGW-log-state-$log_name)
    if [[ $disk -gt $log_vol ]];then
        if [[ "x$state" == "x" ]];then
            $redisShort hset eGW-status eGW-log-state-$log_name 1
            #$redisShort lpush eGW-alarm-log $log_name:1
            log_time=$[$log_ctime-60*60*24]
        else
            $redisShort hset eGW-status eGW-log-state-$log_name $[$state+1]
            log_time=$[$log_ctime-60*60*24*($state+1)]
        fi
    else
        if [[ $state > 0 ]];then
            $redisShort hset eGW-status eGW-log-state-$log_name 0
            #$redisShort lpush eGW-alarm-log $log_name:0
        fi
    fi
    for log in $(ls "-lt"$options $log_path/$log_pattern 2>/dev/null | awk '{print $9}')
    do
        local time_now=$(date +%s)
        local time_stat=$(stat -c %Y $log)
        local time_sub=$[$time_now - $time_stat]
        if [[ $time_sub -gt $log_time ]];then
            rm -rf $log
        fi
    done
    # 999999999 时，关闭 num 计数
    if [[ $log_num != "999999999" ]];then
        ls "-lt"$options $log_path/$log_pattern 2>/dev/null | awk -v log_num=$log_num '{if(NR>log_num){print $9}}' | xargs rm -rf
    fi
}

function compress_log() {
    local log_path=$1
    local log_pattern=$2
    local log_num=$3
    local options=$4
    pushd $log_path &>/dev/null
    for log in $(ls "-lt"$options $log_pattern 2>/dev/null|awk -v log_num=$log_num '!/tgz/{if(NR>log_num){print $9}}')
    do
        tar -zcf $log.tgz $log
        rm -rf $log
    done
    popd &>/dev/null
    #ls "-lt"$options $log_path 2>/dev/null | awk '{if(NR>1){print $9}}' | xargs -I {} sh -c "tar -zcf {}.tgz {} && rm -rf {}"
}

function ps_log() {
    local path="$WATCHDOG_LOG_DIR"
    local pattern="ps*.log"
    local num="1"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "ps_log"
}

function history_log() {
    local path="$LOG_DIR/history"
    local pattern="*.log"
    local num="1"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "history_log"
}

function keepalived_log() {
    local path="$LOG_DIR/keepalived"
    local pattern="*.log"
    local num="1"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "keepalived_log"
}

function ltegwd_log() {
    local path="$LOG_DIR/ltegwd"
    local pattern="egw.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "ltegwd_log"
}

function sctpd_log() {
    local path="$LOG_DIR/sctpd"
    local pattern="sctpd.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "sctpd_log"
}

function manage_log() {
    local path="$LOG_DIR/omcapi/manage"
    local pattern="egw_manage.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "manage_log"
}

function report_log() {
    local path="$LOG_DIR/omcapi/report"
    local pattern="egw_report.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "report_log"
}

function monitor_log() {
    local path="$LOG_DIR/omcapi/monitor"
    local pattern="egw_monitor.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "monitor_log"
}

function alarm_log() {
    local path="$LOG_DIR/omcapi/alarm"
    local pattern="alarm.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "alarm_log"
}

function vtysh_log() {
    local path="$LOG_DIR/vtysh"
    local pattern="vtysh.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "vtysh_log"
}

function vtyhistory_log() {
    local path="$LOG_DIR/vtyhistory"
    local pattern="vtyhistory.log_*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "vtyhistory_log"
}

function tr069_v2_log() {
    local path="$LOG_DIR/oam_trace/tr069"
    local pattern="tr069.*.log"
    local num="1"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "tr069_v2_log"
}

function ftp_func_log() {
    local path="$LOG_DIR/oam_trace/ftp-func"
    local pattern="ftp-func.*.log"
    local num="1"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "ftp_func_log"
}

function post_office_log() {
    local path="$LOG_DIR/oam_trace/post-office"
    local pattern="post-office.*.log"
    local num="1"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "post_office_log"
}

function core_log() {
    local path="$LOG_DIR/coredump"
    local pattern="core-*"
    local num="0"
    compress_log $path $pattern $num
    del_log $path ${pattern}.tgz $1 $2 $3 "core_log"
}

function crash_log() {
    local path="/var/crash"
    local pattern="*"
    local num="0"
    compress_log $path $pattern $num "d"
    del_log $path ${pattern}.tgz $1 $2 $3 "crash_log" "d"
}
