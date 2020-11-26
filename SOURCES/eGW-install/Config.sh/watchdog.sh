#!/bin/bash -
#########################################################################################
# watchdog
# version:6.0
# update:20181018
#########################################################################################
#[ -f /root/eGW/Config.sh/watchdog_para.conf ] && source /root/eGW/Config.sh/watchdog_para.conf
redisPass=`cat /root/eGW/redis/redis_wcg.conf | awk '/^requirepass/{print $2}'`

function egw_ps() {
    source /root/eGW/Config.sh/watchdog_ps.sh
    export -f ps_ltegwd
    export -f ps_egw_manage
    export -f ps_egw_report
    export -f ps_egw_monitor
    export -f ps_egw_manage_logger
    export -f ipsec_test
    export -f ps_kpiMain

    local watch="/root/eGW/Config.sh/watchdog_ps.sh"
    [[ -z $(ps -ef | grep "ps_ltegwd watchdog_ltegwd_timer$") ]] && \
    $watch ps_ltegwd watchdog_ltegwd_timer &
    [[ -z $(ps -ef | grep "ps_egw_manage watchdog_manage_timer$") ]] && \
    $watch ps_egw_manage watchdog_manage_timer &
    [[ -z $(ps -ef | grep "ps_egw_report watchdog_report_timer$") ]] && \
    $watch ps_egw_report watchdog_report_timer &
    [[ -z $(ps -ef | grep "ps_egw_monitor watchdog_monitor_timer$") ]] && \
    $watch ps_egw_monitor watchdog_monitor_timer &
    [[ -z $(ps -ef | grep "ps_egw_manage_logger watchdog_manage_logger_timer$") ]] && \
    $watch ps_egw_manage_logger watchdog_manage_logger_timer &
    [[ -z $(ps -ef | grep "ps_kpiMain watchdog_kpimain_timer$") ]] && \
    $watch ps_kpiMain watchdog_kpimain_timer &
    [[ -z $(ps -ef | grep "ipsec_test watchdog_ipsec_test_timer$") ]] && \
    $watch ipsec_test watchdog_ipsec_test_timer &
}

function egw_gwrec() {
    source /root/eGW/Config.sh/watchdog_ps.sh
    export -f ps_gwrec
    local watch="/root/eGW/Config.sh/watchdog_ps.sh"
    [[ -z $(ps -ef | grep '/bin/bash - /root/eGW/Config.sh/watchdog_ps.sh ps_gwrec watchdog_ltegwd_timer'$ |awk '{ print $10 }') ]] && \
    $watch ps_gwrec watchdog_ltegwd_timer &
}
#new
function egw_sctpd() {
    source /root/eGW/Config.sh/watchdog_ps.sh
    export -f ps_sctpd
    local watch="/root/eGW/Config.sh/watchdog_ps.sh"
    [[ -z $(ps -ef | grep '/bin/bash - /root/eGW/Config.sh/watchdog_ps.sh ps_sctpd watchdog_ltegwd_timer'$ |awk '{ print $10 }') ]] && \
    $watch ps_sctpd watchdog_ltegwd_timer &
}

function egw_cdr() {
    source /root/eGW/Config.sh/watchdog_cdr.sh
    export -f cdr_all
    export -f cdr_upload
    export -f cdr_compress
    export -f cdr_del

    local watch="/root/eGW/Config.sh/watchdog_cdr.sh"
    [[ -z $(ps -ef | grep "cdr_all watchdog_cdr_timer watchdog_cdr_number$") ]] && \
    $watch cdr_all watchdog_cdr_timer watchdog_cdr_number &
}

function egw_imsi() {
    source /root/eGW/Config.sh/watchdog_imsi.sh
    export -f imsi_all
    export -f imsi_del

    local watch="/root/eGW/Config.sh/watchdog_imsi.sh"
    [[ -z $(ps -ef | grep "imsi_all watchdog_imsi_timer watchdog_imsi_number$") ]] && \
    $watch imsi_all watchdog_imsi_timer watchdog_imsi_number &
}

function egw_log() {
    source /root/eGW/Config.sh/watchdog_log.sh
    export -f ps_log
    export -f history_log
    export -f keepalived_log
    export -f ltegwd_log
    export -f manage_log
    export -f report_log
    export -f monitor_log
    export -f vtysh_log
    
    local watch="/root/eGW/Config.sh/watchdog_log.sh"
    [[ -z $(ps -ef | grep "ps_log watchdog_ps_log_timer watchdog_ps_log_number$") ]] && \
    $watch ps_log watchdog_ps_log_timer watchdog_ps_log_number &
    [[ -z $(ps -ef | grep "history_log watchdog_history_log_timer watchdog_history_log_number$") ]] && \
    $watch history_log watchdog_history_log_timer watchdog_history_log_number &
    [[ -z $(ps -ef | grep "keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number$") ]] && \
    $watch keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number &
    [[ -z $(ps -ef | grep "ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number$") ]] && \
    $watch ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number &
    [[ -z $(ps -ef | grep "manage_log watchdog_manage_log_timer watchdog_manage_log_number$") ]] && \
    $watch manage_log watchdog_manage_log_timer watchdog_manage_log_number &
    [[ -z $(ps -ef | grep "report_log watchdog_report_log_timer watchdog_report_log_number$") ]] && \
    $watch report_log watchdog_report_log_timer watchdog_report_log_number &
    [[ -z $(ps -ef | grep "monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number$") ]] && \
    $watch monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number &
    [[ -z $(ps -ef | grep "vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number$") ]] && \
    $watch vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number &
}

function watchdog_all() {
	if [[ $redisPass ]] ; then
   			local WATCHDOG_SWITCH_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default watchdog_switch)
    		local WATCHDOG_SWITCH_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-set watchdog_switch)
	else
   			local WATCHDOG_SWITCH_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default watchdog_switch)
    		local WATCHDOG_SWITCH_SET=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-set watchdog_switch)
	fi

    local watchdog_switch_default=${WATCHDOG_SWITCH_DEFAULT:-"enable"}
    local watchdog_switch_set=${WATCHDOG_SWITCH_SET}
    local watchdog_switch=${watchdog_switch_set:-$watchdog_switch_default}
    if [[ $watchdog_switch == "enable" ]];then
        echo "watchdog run"
        egw_ps
        egw_cdr
        egw_imsi
        egw_log
    else
        echo "watchdog not run"
    fi
}

function watchdog_gotty() {
    local date_today=$(date -d today +"%Y%m%d")
    local user_all=$(awk -F ':' '/user-all/{print $2}' /root/eGW/gotty.conf)
    local passwd_prefix=$(awk -F ':' '/passwd-prefix/{print $2}' /root/eGW/gotty.conf)
    if [[ -z $(ps -ef|grep "/root/eGW/gotty -w -p 50685 --title-format WCG WEB-CLI /root/eGW/vtysh$") ]];then
        pkill gotty
        #/root/eGW/gotty -w -p 50685 -c $user_all:$passwd_prefix@$date_today --title-format "WCG WEB-CLI" /root/eGW/vtysh &
        /root/eGW/gotty -w -p 50685 --title-format "WCG WEB-CLI" /root/eGW/vtysh &
    fi
}

function watchdog_ipsec() {
    #local timer=$(cat /etc/ipsec.conf | awk '{if(!NF){next}};!/.*#/;p' | awk -F '=' '/ikelifetime/{print $2}')
    source /root/eGW/Config.sh/ipsec.sh
    export -f ipsec_ipxs
    ipsec_ipxs
}

function watchdog() {
    while :
    do
        watchdog_gotty
        watchdog_all
        watchdog_ipsec
        sleep 30
    done
}

function watchdog_gwrec() {
	gwrec_dog=$(ps -ef |grep '/bin/bash - /root/eGW/Config.sh/watchdog_ps.sh ps_gwrec watchdog_ltegwd_timer'$ |awk '{ print $10 }')
    if [[ $gwrec_dog != '/root/eGW/Config.sh/watchdog_ps.sh' ]]; then
        while :
        do
#           watchdog_gotty
            egw_gwrec
            sleep 30
        done
    fi
}
#new
function watchdog_sctpd(){
        sctpd_dog=$(ps -ef |grep '/bin/bash - /root/eGW/Config.sh/watchdog_ps.sh ps_sctpd watchdog_ltegwd_timer'$ |awk '{ print $10 }')
    if [[ $sctpd_dog != '/root/eGW/Config.sh/watchdog_ps.sh' ]]; then
        while :
        do
#           watchdog_gotty
            egw_sctpd
            sleep 30
        done
    fi
}
