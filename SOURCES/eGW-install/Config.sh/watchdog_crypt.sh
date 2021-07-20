#!/usr/bin/env bash
#########################################################################################
# watchdog_crypt.sh
# version:1.0
# update:20210129
#########################################################################################


while :
do
    egw_logs=$(ls /root/eGW/Logs/ltegwd/.egw.log* 2>/dev/null)
    sctpd_logs=$(ls /root/eGW/Logs/sctpd/.sctpd.log* 2>/dev/null)
    vtysh_logs=$(ls /root/eGW/Logs/vtysh/.vtysh.log* 2>/dev/null)
    egw_report_logs=$(ls /root/eGW/Logs/omcapi/report/.egw_report.log* 2>/dev/null)
    egw_manage_logs=$(ls /root/eGW/Logs/omcapi/manage/.egw_manage.log* 2>/dev/null)
    egw_monitor_logs=$(ls /root/eGW/Logs/omcapi/monitor/.egw_monitor.log* 2>/dev/null)
    
    for logs in $egw_logs $sctpd_logs $vtysh_logs $egw_report_logs $egw_manage_logs $egw_monitor_logs
    do
        /root/eGW/.Config.sh/crypt.sh -c "$logs"
        echo ${logs} |egrep ".log$" >/dev/null || rm -rf "$logs"
    done
    
    sleep 3
done
