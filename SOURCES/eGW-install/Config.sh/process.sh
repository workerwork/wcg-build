#!/bin/bash -
#########################################################################################
# process.sh
# version:5.0
# update:20210520
#########################################################################################
function start_egw_manage() {
    export exec_egw_manage="$OMC_DIR/egw_manage"
    spawn-fcgi -a 127.0.0.1 -p 8089 -f $exec_egw_manage
}

function start_egw_report() {
    export exec_egw_report="$OMC_DIR/egw_report"
    $exec_egw_report &
}

function start_egw_manage_logger() {
    export exec_egw_manage_logger="$OMC_DIR/egw_manage_logger"
    $exec_egw_manage_logger &
}

function start_egw_monitor() {
    export exec_egw_monitor="$OMC_DIR/egw_monitor"
    $exec_egw_monitor &
}

function start_gtp_ko() {
    lsmod | grep gtp_relay
    if [[ $? == 0 ]];then
        rmmod $GTP_KO
        insmod $GTP_KO
    else
        insmod $GTP_KO
    fi
}

function start_ltegwd() {
    export exec_ltegwd="$BASE_DIR/ltegwd 4"
    $exec_ltegwd &
}

function start_sctpd() {
    export exec_sctpd="$BASE_DIR/sctpd"
    $exec_sctpd &
}

function start_KPIMain() {
    export exec_KPIMain="$OMC_DIR/kpiMain"
    $exec_KPIMain &
}

function process() {
    start_egw_manage && export -f start_egw_manage
    start_egw_manage_logger && export -f start_egw_manage_logger
    start_egw_report && export -f start_egw_report
    start_egw_monitor && export -f start_egw_monitor
    start_gtp_ko && export -f start_gtp_ko
    start_ltegwd && export -f start_ltegwd
    start_sctpd && export -f start_sctpd
    start_KPIMain && export -f start_KPIMain
}
