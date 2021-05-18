#!/bin/bash -
#########################################################################################
# watchdog_ps.sh
# version:4.0
# update:20181018
#########################################################################################
redisPass=`cat /root/eGW/redis/redis_wcg.conf | awk '/^requirepass/{print $2}'`
function watch_ps() {
    task=$1
    timer=$2
    while :
    do
		if [[ $redisPass ]]; then
        	sleep_timer_default=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default $timer)
        	sleep_timer_set=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-set $timer)
        	sleep_timer=${sleep_timer_set:-$sleep_timer_default}
		else
        	sleep_timer_default=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default $timer)
        	sleep_timer_set=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-set $timer)
        	sleep_timer=${sleep_timer_set:-$sleep_timer_default}
		fi
        if [[ $sleep_timer == 0  ]];then
            sleep 5
        else
            $task && sleep ${sleep_timer:-"5"} || exit 1
        fi
    done
}

[[ $1 ]] && watch_ps $1 $2

function ps_ltegwd() {
    ltegwd=$(ps -ef |grep '/root/eGW/ltegwd'|grep -v 'grep' |awk '{ print $8 }')
 	if [[ $ltegwd != '/root/eGW/ltegwd' ]] && [[ -f /root/eGW/lo.bin ]] && [[ -f /root/eGW/ls.bin ]];then       
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: ltegwd restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof ltegwd)
        [[ $tpid ]] && kill -9 $tpid
		if [[ $redisPass ]]; then
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-ltegwd 1
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps ltegwd:1
		else
        	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-ltegwd 1
        	redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps ltegwd:1
		fi
        . /root/eGW/Config.sh/process.sh
        ltegwd
        #find /root/eGW -maxdepth 1 -name "*.imsi" -print0 | xargs -0I {} mv -f {} /root/eGW/ImsiFiles
    	else		
		if [[ $redisPass ]]; then
        	ltegwd_state=$(redis-cli -h 127.0.0.1 -p 9736 hget -a $redisPass eGW-status eGW-ps-state-ltegwd)
        	if [[ $ltegwd_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps ltegwd:0
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-ltegwd 0
        	fi
		else
        	ltegwd_state=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ps-state-ltegwd)
        	if [[ $ltegwd_state == 1 ]]; then
        	    redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps ltegwd:0
        	    redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-ltegwd 0
        	fi
		fi
    fi
}

function ps_gwrec() {
    gwrec=$(ps -ef |grep 'gwrec'$ |grep -v 'grep' |awk '{ print $8 }')
    if [[ $gwrec != '/root/eGW/gwrec' ]] && [[ -f /root/eGW/lo.bin ]] && [[ -f /root/eGW/ls.bin ]];then
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: gwrec restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof gwrec)
        [[ $tpid ]] && kill -9 $tpid
		    /root/eGW/gwrec &
        #find /root/eGW -maxdepth 1 -name "*.imsi" -print0 | xargs -0I {} mv -f {} /root/eGW/ImsiFiles
    fi
}

function ipsec_test() {
	if [[ $redisPass ]]; then
		IPSEC_UPLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_ipsec_uplink_switch)
		IPSEC_UPLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-set config_ipsec_uplink_switch)
	else
		IPSEC_UPLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_ipsec_uplink_switch)
		IPSEC_UPLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-set config_ipsec_uplink_switch)
	fi
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
	local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    local CDIR=/root/eGW/Config.sh/.config
    [[ ! -d $CDIR ]] && mkdir -p $CDIR

	/root/eGW/Tools/egwTool -P > $CDIR/config.save
	if [[ $redisPass ]];then
	  local ipsec_uplink_flag=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ipsec-state-uplink)
	else
	  local ipsec_uplink_flag=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ipsec-state-uplink)
	fi

    if [[ $ipsec_uplink ==  "enable" ]];then
	if [[ $redisPass ]]; then
            redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ipsec-state-uplink 1
	else
            redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ipsec-state-uplink 1
	fi

        local ip_ipsec=`ipsec status | grep client | grep === | awk '{print $2}' | awk 'BEGIN {FS = "/"} {print $1}'`
        uplink_addr=$(/root/eGW/Tools/egwTool -P | awk '/gtpu-uplink/{print $3;exit}')
        if [[ $ip_ipsec != $uplink_addr ]] && [[ $ip_ipsec ]];then
            sed -i "s/\(ip_ipsec\).*/\1 $ip_ipsec/g" $CDIR/config.save
            local cp_ip=$(awk '/macro-enblink/{print $5}' $CDIR/config.save)
            local up_ip=$(awk '/gtpu-uplink/{print $3}' $CDIR/config.save)
            local ip_conf=$ip_ipsec
            for ip in $cp_ip
            do
              /root/eGW/Tools/egwTool -P | \
              awk -v ip=$ip -v ip_conf=$ip_conf '{if($1~/macro-enblink/ && $5==ip && $3!="ipv6"){system("/root/eGW/Tools/egwTool -f "$5":"ip_conf );exit}}'
	    done

            for ip in $up_ip
            do
                /root/eGW/Tools/egwTool -P | \
                awk -v ip=$ip -v ip_conf=$ip_conf '{if($1~/gtpu-uplink/ && $3==ip && $3!="ipv6"){system("/root/eGW/Tools/egwTool -f "$3":"ip_conf);exit}}'
            done
            pkill ltegwd
            . /root/eGW/Config.sh/process.sh
            ltegwd

            time_all=`date +%Y-%m-%d' '%H:%M:%S`
            time_Ymd=`date +%Y%m%d`
            echo $time_all " watchdog: ipsec_addr changed" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        fi
    fi

	if [[ $ipsec_uplink ==  "disable" ]] && [[ $ipsec_uplink_flag == "1" ]];then
	    if [[ $redisPass ]]; then
	 	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ipsec-state-uplink 0
	    else
		redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ipsec-state-uplink 0
	    fi

        pkill ltegwd
        . /root/eGW/Config.sh/process.sh
        ltegwd
	    time_all=`date +%Y-%m-%d' '%H:%M:%S`
	    time_Ymd=`date +%Y%m%d`
	    echo $time_all " watchdog: ipsec_addr changed" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
	fi
}


function ps_egw_manage() {
    egw_manage=`ps -ef |grep egw_manage$ |awk '{ print $8 }'`
    if [[ $egw_manage != '/root/eGW/OMC/egw_manage' ]];then
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_manage restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_manage)
        [[ $tpid ]] && kill -9 $tpid
		if [[ $redisPass ]]; then
   	    	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_manage 1
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_manage:1
		else
   	    	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_manage 1
        	redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_manage:1
		fi
        spawn-fcgi -a 127.0.0.1 -p 8089 -f /root/eGW/OMC/egw_manage
    else
		if [[ $redisPass ]]; then
        	egw_manage_state=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ps-state-egw_manage)
        	if [[ $egw_manage_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_manage:0
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_manage 0
        	fi
		else
        	egw_manage_state=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ps-state-egw_manage)
        	if [[ $egw_manage_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_manage:0
        	    redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_manage 0
        	fi
		fi
    fi
}

function ps_egw_report() {
    egw_report=`ps -ef |grep egw_report$ |awk '{ print $8 }'`
    if [[ $egw_report != '/root/eGW/OMC/egw_report' ]];then
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_report restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_report)
        [[ $tpid ]] && kill -9 $tpid 
		if [[ $redisPass ]]; then
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_report 1
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_report:1
		else
        	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_report 1
        	redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_report:1
		fi
        /root/eGW/OMC/egw_report &
    else
		if [[ $redisPass ]]; then
        	egw_report_state=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ps-state-egw_report)
        	if [[ $egw_report_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_report:0
            	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_report 0
        	fi
		else
        	egw_report_state=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ps-state-egw_report)
        	if [[ $egw_report_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_report:0
            	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_report 0
        	fi
		fi
    fi
}

function ps_egw_monitor() {
    egw_monitor=`ps -ef |grep egw_monitor$ |awk '{ print $8 }'`
    if [[ $egw_monitor != '/root/eGW/OMC/egw_monitor' ]];then
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_monitor restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_monitor)	
        [[ $tpid ]] && kill -9 $tpid 
		if [[ $redisPass ]]; then
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_monitor 1
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_monitor:1
		else
        	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_monitor 1
        	redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_monitor:1
		fi
        /root/eGW/OMC/egw_monitor &
    else
		if [[ $redisPass ]]; then
        	egw_monitor_state=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ps-state-egw_monitor)
        	if [[ $egw_monitor_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_monitor:0
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_monitor 0
        	fi
		else
        	egw_monitor_state=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ps-state-egw_monitor)
        	if [[ $egw_monitor_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_monitor:0
        	    redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_monitor 0
        	fi
		fi
    fi
}

function ps_egw_manage_logger() {
    egw_manage_logger=`ps -ef |grep egw_manage_logger$ |awk '{ print $8 }'`
    if [[ $egw_manage_logger != '/root/eGW/OMC/egw_manage_logger' ]];then
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: egw_manage_logger restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof egw_manage_logger)
        [[ $tpid ]] && kill -9 $tpid 
		if [[ $redisPass ]]; then
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_manage_logger 1
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_manage_logger:1
		else
        	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_manage_logger 1
        	redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_manage_logger:1
		fi
        /root/eGW/OMC/egw_manage_logger &
    else
		if [[ $redisPass ]]; then
        	egw_manage_logger_state=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ps-state-egw_manage_logger)
        	if [[ $egw_manage_logger_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps egw_manage_logger:0
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-egw_manage_logger 0
        	fi
		else
        	egw_manage_logger_state=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ps-state-egw_manage_logger)
        	if [[ $egw_manage_logger_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps egw_manage_logger:0
        	    redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-egw_manage_logger 0
        	fi
		fi
    fi
}

function ps_tftp() {
    tftp_enable=`cat /root/eGW/networkcfg.conf |grep ^set_tftp_enable |awk '{print $2}'`
    if [[ $tftp_enable -eq 1 ]];then
        tftp_status=$(netstat -aux |grep tftp |grep "udp ")
        if [[ ! -n $tftp_status ]];then
            systemctl restart xinetd
            time_all=`date +%Y-%m-%d' '%H:%M:%S`
            time_Ymd=`date +%Y%m%d`
            echo $time_all " watchdog: tftp restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        fi
    fi
}

function ps_kpiMain() {
    kpiMain=`ps -ef |grep kpiMain$ |awk '{ print $8 }'`
    if [[ $kpiMain != '/root/eGW/OMC/kpiMain' ]];then
        /root/eGW/Tools/autoinfo &
        time_all=`date +%Y-%m-%d' '%H:%M:%S`
        time_Ymd=`date +%Y%m%d`
        echo $time_all " watchdog: kpiMain restart" >> /root/eGW/Logs/watchdog/ps_${time_Ymd}.log
        local tpid=$(pidof kpiMain)
        [[ $tpid ]] && kill -9 $tpid 
		if [[ $redisPass ]]; then
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-kpiMain 1
        	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps kpiMain:1
		else
        	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-kpiMain 1
        	redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps kpiMain:1
		fi
        /root/eGW/OMC/kpiMain &
    else
		if [[ $redisPass ]]; then
        	kpiMain_state=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ps-state-kpiMain)
        	if [[ $kpiMain_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 -a $redisPass lpush eGW-alarm-ps kpiMain:0
            	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ps-state-kpiMain 0
        	fi
		else
        	kpiMain_state=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ps-state-kpiMain)
        	if [[ $kpiMain_state == 1 ]];then
        	    redis-cli -h 127.0.0.1 -p 9736 lpush eGW-alarm-ps kpiMain:0
            	redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ps-state-kpiMain 0
        	fi
		fi
    fi
}

