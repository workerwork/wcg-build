#!/bin/bash -
#########################################################################################
# watchdog
# version:5.0
# update:20210520
#########################################################################################
function ps_ef() {
    if [[ "x$3" == "x" ]];then
        [[ -z $(ps -ef | grep "${1} ${2}$") ]] && $watch $1 $2 &
    else
        [[ -z $(ps -ef | grep "${1} ${2} ${3}$") ]] && $watch $1 $2 $3 &	
    fi
}

function egw_ps() {
    source $CUR_DIR/watchdog_ps.sh
    export -f ps_ltegwd
    export -f ps_sctpd
    export -f ps_gwrec
    export -f ps_egw_manage
    export -f ps_egw_report
    export -f ps_egw_monitor
    export -f ps_egw_manage_logger
    export -f ps_kpiMain
    export -f watchdog_log
    export -f ipsec_test

    local watch="$CUR_DIR/watchdog_ps.sh"
    ps_ef ps_gwrec watchdog_gwrec_timer
    ps_ef ps_ltegwd watchdog_ltegwd_timer
    ps_ef ps_sctpd watchdog_sctpd_timer
    ps_ef ps_egw_manage watchdog_manage_timer
    ps_ef ps_egw_report watchdog_report_timer
    ps_ef ps_egw_monitor watchdog_monitor_timer
    ps_ef ps_egw_manage_logger watchdog_manage_logger_timer
    ps_ef ps_kpiMain watchdog_kpimain_timer
    ps_ef ipsec_test watchdog_ipsec_test_timer
}

function egw_log() {
    source $CUR_DIR/watchdog_log.sh
    export -f del_log
    export -f ps_log
    export -f history_log
    export -f keepalived_log
    export -f ltegwd_log
    export -f sctpd_log
    export -f manage_log
    export -f report_log
    export -f monitor_log
    export -f vtysh_log
    export -f core_log
    export -f crash_log
    
    local watch="$CUR_DIR/watchdog_log.sh"
    ps_ef ps_log watchdog_ps_log_timer watchdog_ps_log_number
    ps_ef keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number
    ps_ef ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number
    ps_ef sctpd_log watchdog_sctpd_log_timer watchdog_sctpd_log_number
    ps_ef manage_log watchdog_manage_log_timer watchdog_manage_log_number
    ps_ef report_log watchdog_report_log_timer watchdog_report_log_number
    ps_ef monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number
    ps_ef vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number
    ps_ef history_log watchdog_history_log_timer watchdog_history_log_number
    ps_ef core_log watchdog_core_log_timer watchdog_core_log_number
    ps_ef crash_log watchdog_crash_log_timer watchdog_crash_log_number
}

function watchdog_all() {
    local WATCHDOG_SWITCH_DEFAULT=$($redisShort hget eGW-para-default watchdog_switch)
    local WATCHDOG_SWITCH_SET=$($redisShort hget eGW-para-set watchdog_switch)
    local watchdog_switch_default=${WATCHDOG_SWITCH_DEFAULT:-"enable"}
    local watchdog_switch_set=${WATCHDOG_SWITCH_SET}
    local watchdog_switch=${watchdog_switch_set:-$watchdog_switch_default}
    if [[ $watchdog_switch == "enable" ]];then
        echo "watchdog run"
        egw_ps
        egw_log
    else
        echo "watchdog not run"
    fi
}

function watchdog_gotty() {
    local date_today=$(date -d today +"%Y%m%d")
    local user_all=$(awk -F ':' '/user-all/{print $2}' $GOTTY_CONF)
    local passwd_prefix=$(awk -F ':' '/passwd-prefix/{print $2}' $GOTTY_CONF)
    local gotty="$GOTTY -w -p 50685 -c $user_all:$passwd_prefix@$date_today --title-format WCG WEB-CLI ${VTYSH}"
    if [[ -z $(ps -ef|grep "${gotty}$") ]];then
        pkill gotty
        $gotty &
    fi
}

function watchdog_ipsec() {
    source $CUR_DIR/ipsec.sh
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

