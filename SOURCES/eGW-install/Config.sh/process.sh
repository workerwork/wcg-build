#!/bin/bash -
#########################################################################################
# process.sh
# version:3.2
# update:20180625
#########################################################################################
function egw_manage() {
    spawn-fcgi -a 127.0.0.1 -p 8089 -f /root/eGW/OMC/egw_manage
}

function egw_report() {
    /root/eGW/OMC/egw_report &
}

function egw_manage_logger() {
    /root/eGW/OMC/egw_manage_logger &
}

function egw_monitor() {
    /root/eGW/OMC/egw_monitor &
}

function gtp_ko() {
    lsmod | grep gtp_relay
    if [[ $? == 0 ]];then
        rmmod /root/eGW/gtp-relay.ko
        insmod /root/eGW/gtp-relay.ko
    else
        insmod /root/eGW/gtp-relay.ko
    fi
}

function gwrec() {
    gwrec_p=$(ps -ef |grep 'gwrec'$ |awk '{ print $8 }')
    if [[ $gwrec_p != '/root/eGW/gwrec' ]] && [[ -f /root/eGW/lo.bin ]] && [[ -f /root/eGW/ls.bin ]];then
        local tpid=$(pidof gwrec)
        [[ $tpid ]] && kill -9 $tpid
		    /root/eGW/gwrec &
    fi
}

function ltegwd() {
    /root/eGW/ltegwd 8 4 &
}

function sctpd() {
    /root/eGW/sctpd &
}

function KPIMain() {
    /root/eGW/OMC/kpiMain &
}

function process() {
    sctpd
    while :
    do
        sctpd_process=$(ps -ef |grep 'sctpd'$ |awk '{ print $8 }')
        if [[ $sctpd_process != '/root/eGW/sctpd' ]];then       
            continue;
        else
            break;
        fi
    done
    egw_manage
    egw_manage_logger
    egw_report
    egw_monitor
    gtp_ko
    gwrec

    ltegwd
    KPIMain
}
