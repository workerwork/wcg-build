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
    $redisShort del eGWActiveEnb &>/dev/null
    $redisShort del eGWConnectedUe &>/dev/null
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

function start_autoinfo() {
    $TOOLS_DIR/autoinfo &
}

function process() {
    export -f start_autoinfo
    start_bins="start_egw_manage 
                start_egw_manage_logger 
                start_egw_report
                start_egw_monitor 
                start_gtp_ko 
                start_ltegwd 
                start_sctpd 
                start_KPIMain"
    for start_bin in $start_bins
    do
        $start_bin && export -f $start_bin
    done
}
