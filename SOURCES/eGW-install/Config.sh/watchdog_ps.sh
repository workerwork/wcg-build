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
        sleep_timer_default=$($redisShort hget eGW-para-default $timer)
        sleep_timer_set=$($redisShort hget eGW-para-set $timer)
        sleep_timer=${sleep_timer_set:-$sleep_timer_default}
        if [[ $sleep_timer == 0  ]];then
            sleep 5
        else
            $task && sleep ${sleep_timer:-"5"} || exit 1
        fi
    done
}

[[ $1 ]] && watch_ps $1 $2

function watchdog_log() {
    time_all=$(date +%Y-%m-%d' '%H:%M:%S)
    time_Ymd=$(date +%Y%m%d)
    echo $time_all " watchdog: $1 " >> $WATCHDOG_LOG_PATH/ps_${time_Ymd}.log
}

function ps_ltegwd() {
    local count=$(ps -ef |grep ${exec_ltegwd}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]] && [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then       
        start_autoinfo
        watchdog_log "ltegwd restart"
        $redisShort hset eGW-status eGW-ps-state-ltegwd 1
        $redisShort lpush eGW-alarm-ps ltegwd:1
	start_ltegwd 
    else		
        ltegwd_state=$($redisShort hget eGW-status eGW-ps-state-ltegwd)
        if [[ $ltegwd_state == 1 ]];then
            $redisShort lpush eGW-alarm-ps ltegwd:0
            $redisShort hset eGW-status eGW-ps-state-ltegwd 0
        fi
    fi
}

function ps_gwrec() {
    local count=$(ps -ef |grep ${exec_gwrec}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]] && [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then
        start_autoinfo
        watchdog_log "gwrec restart"
        start_gwrec
    fi
}

function ps_sctpd() {
    local count=$(ps -ef |grep ${exec_sctpd}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]] && [[ -f $BASE_DIR/lo.bin ]] && [[ -f $BASE_DIR/ls.bin ]];then
        start_autoinfo
        watchdog_log "sctpd restart"
        pkill ltegwd
        $redisShort del eGWActiveEnb &>/dev/null
        $redisShort del eGWConnectedUe &>/dev/null
        start_gtp_ko
        start_ltegwd	
        start_sctpd
    fi
}

function ps_egw_manage() {
    local count=$(ps -ef |grep ${exec_egw_manage}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]];then
        start_autoinfo
        watchdog_log "egw_manage restart"
        $redisShort hset eGW-status eGW-ps-state-egw_manage 1
        $redisShort lpush eGW-alarm-ps egw_manage:1
        start_egw_manage
    else
        egw_manage_state=$($redisShort hget eGW-status eGW-ps-state-egw_manage)
        if [[ $egw_manage_state == 1 ]];then
            $redisShort lpush eGW-alarm-ps egw_manage:0
            $redisShort hset eGW-status eGW-ps-state-egw_manage 0
        fi
    fi
}

function ps_egw_report() {
    local count=$(ps -ef |grep ${exec_egw_report}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]];then
        start_autoinfo
        watchdog_log "egw_report restart"
        $redisShort hset eGW-status eGW-ps-state-egw_report 1
        $redisShort lpush eGW-alarm-ps egw_report:1
        start_egw_report
    else
        egw_report_state=$($redisShort hget eGW-status eGW-ps-state-egw_report)
        if [[ $egw_report_state == 1 ]];then
            $redisShort lpush eGW-alarm-ps egw_report:0
            $redisShort hset eGW-status eGW-ps-state-egw_report 0
        fi
    fi
}

function ps_egw_monitor() {
    local count=$(ps -ef |grep ${exec_egw_monitor}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]];then
        start_autoinfo
        watchdog_log "egw_monitor restart"
        $redisShort hset eGW-status eGW-ps-state-egw_monitor 1
        $redisShort lpush eGW-alarm-ps egw_monitor:1
        start_egw_monitor
    else
        egw_monitor_state=$($redisShort hget eGW-status eGW-ps-state-egw_monitor)
        if [[ $egw_monitor_state == 1 ]];then
            $redisShort lpush eGW-alarm-ps egw_monitor:0
            $redisShort hset eGW-status eGW-ps-state-egw_monitor 0
        fi
    fi
}

function ps_egw_manage_logger() {
    local count=$(ps -ef |grep ${exec_egw_manage_logger}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]];then
        start_autoinfo
        watchdog_log "egw_manage_logger restart"
        $redisShort hset eGW-status eGW-ps-state-egw_manage_logger 1
        $redisShort lpush eGW-alarm-ps egw_manage_logger:1
        start_egw_manage_logger
    else
        egw_manage_logger_state=$($redisShort hget eGW-status eGW-ps-state-egw_manage_logger)
        if [[ $egw_manage_logger_state == 1 ]];then
            $redisShort lpush eGW-alarm-ps egw_manage_logger:0
            $redisShort hset eGW-status eGW-ps-state-egw_manage_logger 0
        fi
    fi
}


function ps_kpiMain() {
    local count=$(ps -ef |grep ${exec_kpiMain}$|grep -v 'grep'|wc -l)
    if [[ $count == 0 ]];then
        start_autoinfo
        watchdog_log "kpiMain restart"
        $redisShort hset eGW-status eGW-ps-state-kpiMain 1
        $redisShort lpush eGW-alarm-ps kpiMain:1
        start_KPIMain
    else
        kpiMain_state=$($redisShort hget eGW-status eGW-ps-state-kpiMain)
        if [[ $kpiMain_state == 1 ]];then
            $redisShort lpush eGW-alarm-ps kpiMain:0
            $redisShort hset eGW-status eGW-ps-state-kpiMain 0
        fi
    fi
}

#ipsec up自动替换，ipsec down 提示手工替换，egwTool自身实现限制
function ipsec_test() {
    local ipsec_uplink_default=$($redisShort hget eGW-para-default config_ipsec_uplink_switch)
    local ipsec_uplink_set=$($redisShort hget eGW-para-set config_ipsec_uplink_switch)
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    if [[ $ipsec_uplink ==  "enable" ]];then
        local uplink_addr=$($TOOLS_DIR/egwTool -P | awk '/gtpu-uplink/{print $3;exit}')
        local ip_ipsec=$(ipsec status | grep client | grep === | awk '{print $2}' | awk 'BEGIN {FS = "/"} {print $1}')
        if [[ $ip_ipsec != $uplink_addr ]] && [[ $ip_ipsec ]];then
            $TOOLS_DIR/egwTool -P |awk -v ip=$uplink_addr -v ip_conf=$ip_ipsec '{if($1~/macro-enblink/ && $5==ip && $3!="ipv6"){system("/root/eGW/Tools/egwTool -f "$5":"ip_conf );exit}}'
            pkill ltegwd
            start_ltegwd
            watchdog_log "ipsec_add changed"
        fi
    fi
}

