#!/usr/bin/env bash
#########################################################################################
# watchdog_crypt.sh
# version:2.0
# update:20210805
#########################################################################################
log_dir="/var/log/eGW"

while :
do
    egw_logs=$(ls $log_dir/ltegwd/.egw.log* 2>/dev/null)
    sctpd_logs=$(ls $log_dir/sctpd/.sctpd.log* 2>/dev/null)
    vtysh_logs=$(ls $log_dir/vtysh/.vtysh.log* 2>/dev/null)
    egw_report_logs=$(ls $log_dir/omcapi/report/.egw_report.log* 2>/dev/null)
    egw_manage_logs=$(ls $log_dir/omcapi/manage/.egw_manage.log* 2>/dev/null)
    egw_monitor_logs=$(ls $log_dir/omcapi/monitor/.egw_monitor.log* 2>/dev/null)
    
    for logs in $egw_logs $sctpd_logs $vtysh_logs $egw_report_logs $egw_manage_logs $egw_monitor_logs
    do
        /usr/lib/eGW/.Config.sh/crypt.sh -c "$logs"
        echo ${logs} |egrep ".log$" >/dev/null || rm -rf "$logs"
    done
    
    sleep 3
done
