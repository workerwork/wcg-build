#!/bin/bash -
#########################################################################################
# watchdog
# version:5.0
# update:20210520
#########################################################################################
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

    local watch="$CUR_DIR/watchdog_ps.sh"
    [[ -z $(ps -ef | grep "ps_gwrec watchdog_gwrec_timer$") ]] && $watch ps_gwrec watchdog_gwrec_timer &
    [[ -z $(ps -ef | grep "ps_ltegwd watchdog_ltegwd_timer$") ]] && $watch ps_ltegwd watchdog_ltegwd_timer &
    [[ -z $(ps -ef | grep "ps_sctpd watchdog_sctpd_timer$") ]] && $watch ps_sctpd watchdog_sctpd_timer &
    [[ -z $(ps -ef | grep "ps_egw_manage watchdog_manage_timer$") ]] && $watch ps_egw_manage watchdog_manage_timer &
    [[ -z $(ps -ef | grep "ps_egw_report watchdog_report_timer$") ]] && $watch ps_egw_report watchdog_report_timer &
    [[ -z $(ps -ef | grep "ps_egw_monitor watchdog_monitor_timer$") ]] && $watch ps_egw_monitor watchdog_monitor_timer &
    [[ -z $(ps -ef | grep "ps_egw_manage_logger watchdog_manage_logger_timer$") ]] && $watch ps_egw_manage_logger watchdog_manage_logger_timer &
    [[ -z $(ps -ef | grep "ps_kpiMain watchdog_kpimain_timer$") ]] && $watch ps_kpiMain watchdog_kpimain_timer &
}

function egw_log() {
    source $CUR_DIR/watchdog_log.sh
    export -f ps_log
    export -f history_log
    export -f keepalived_log
    export -f ltegwd_log
    export -f sctpd_log
    export -f manage_log
    export -f report_log
    export -f monitor_log
    export -f vtysh_log
    
    local watch="$CUR_DIR/watchdog_log.sh"
    [[ -z $(ps -ef | grep "ps_log watchdog_ps_log_timer watchdog_ps_log_number$") ]] && $watch ps_log watchdog_ps_log_timer watchdog_ps_log_number &
    [[ -z $(ps -ef | grep "history_log watchdog_history_log_timer watchdog_history_log_number$") ]] && $watch history_log watchdog_history_log_timer watchdog_history_log_number &
    [[ -z $(ps -ef | grep "keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number$") ]] && $watch keepalived_log watchdog_keepalived_log_timer watchdog_keepalived_log_number &
    [[ -z $(ps -ef | grep "ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number$") ]] && $watch ltegwd_log watchdog_ltegwd_log_timer watchdog_ltegwd_log_number &
    [[ -z $(ps -ef | grep "sctpd_log watchdog_sctpd_log_timer watchdog_sctpd_log_number$") ]] && $watch sctpd_log watchdog_sctpd_log_timer watchdog_sctpd_log_number &
    [[ -z $(ps -ef | grep "manage_log watchdog_manage_log_timer watchdog_manage_log_number$") ]] && $watch manage_log watchdog_manage_log_timer watchdog_manage_log_number &
    [[ -z $(ps -ef | grep "report_log watchdog_report_log_timer watchdog_report_log_number$") ]] && $watch report_log watchdog_report_log_timer watchdog_report_log_number &
    [[ -z $(ps -ef | grep "monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number$") ]] && $watch monitor_log watchdog_monitor_log_timer watchdog_monitor_log_number &
    [[ -z $(ps -ef | grep "vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number$") ]] && $watch vtysh_log watchdog_vtysh_log_timer watchdog_vtysh_log_number &
}

function watchdog_all() {
    local WATCHDOG_SWITCH_DEFAULT=$(redis-cli -h $redisHost -p $redisPort -a "$redisPass" hget eGW-para-default watchdog_switch)
    local WATCHDOG_SWITCH_SET=$(redis-cli -h $redisHost -p $redisPort -a "$redisPass" hget eGW-para-set watchdog_switch)
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
    if [[ -z $(ps -ef|grep "$GOTTY -w -p 50685 -c $user_all:$passwd_prefix@$date_today --title-format WCG WEB-CLI ${VTYSH}$") ]];then
        pkill gotty
        $GOTTY -w -p 50685 -c $user_all:$passwd_prefix@$date_today --title-format "WCG WEB-CLI" ${VTYSH} &
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

