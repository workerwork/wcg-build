#!/bin/bash -
#########################################################################################
# process.sh
# version:6.0
# update:20210805
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

function start_gwrec() {
    export exec_gwrec="$LIB_DIR/gwrec"
    #[[ $1 ]] && $exec_gwrec &  
    if [[ -f $LIB_DIR/lo.bin ]] && [[ -f $LIB_DIR/ls.bin ]];then
        $exec_gwrec &
    else
        echo "can't start gwrec,exit!"
        exit 1
    fi
}

function start_post_office() {
    export exec_post_office="$TR069_DIR/post-office"
    $exec_post_office & 
}

function start_ftp_func() {
    export exec_ftp_func="$TR069_DIR/ftp-func"
    $exec_ftp_func &
}

function start_tr069_v2() {
    export exec_tr069_v2="$TR069_DIR/tr069-v2"
    $exec_tr069_v2 &
}

function start_ltegwd() {
    export exec_ltegwd="$LIB_DIR/ltegwd"
    $exec_ltegwd &
}

function start_sctpd() {
    export exec_sctpd="$LIB_DIR/sctpd"
    $exec_sctpd &
}

function start_kpiMain() {
    export exec_kpiMain="$OMC_DIR/kpiMain"
    $exec_kpiMain &
}

function start_autoinfo() {
    $TOOLS_DIR/autoinfo &
}

function process_before_ha() {
    start_bins="start_gwrec
		start_post_office
		start_ftp_func
		start_tr069_v2"   
    for start_bin in $start_bins
    do
        $start_bin && export -f $start_bin       
    done
}

function process_after_ha() {
    export -f start_autoinfo
    start_bins="start_egw_manage 
                start_egw_manage_logger 
                start_egw_report
                start_egw_monitor 
                start_gtp_ko 
                start_ltegwd 
                start_sctpd 
                start_kpiMain"
    for start_bin in $start_bins
    do
        $start_bin && export -f $start_bin
    done
}
