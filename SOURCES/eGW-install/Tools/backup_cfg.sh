#!/bin/bash


if [ $1 == "ipsec" ];then
	echo "ipsec configuration back to /root/DailyBackUp"
	if [ ! -e /root/DailyBackUp ];then
		mkdir -p /root/DailyBackUp
	fi
	
	cd /root/DailyBackUp
	dateStr="ipsec"`date +%Y-%m-%d-%H:%M:%S`
	
	if [ ! -e dateStr ];then
		mkdir -p $dateStr
	fi
	
	cd /root/DailyBackUp/$dateStr
	cp /etc/ipsec.conf .
	cp /etc/ipsec.secrets .
elif [ $1 == "wcg" ];then
        echo "wcg configuration back to /root/DailyBackUp"
        if [ ! -e /root/DailyBackUp ];then
                mkdir -p /root/DailyBackUp
        fi
	cd /root/DailyBackUp
        dateStr="wcg"`date +%Y-%m-%d-%H:%M:%S`

        if [ ! -e dateStr ];then
                mkdir -p $dateStr
        fi

        cd /root/DailyBackUp/$dateStr
        cp /root/eGW/ltegwd.xml .
        cp /root/eGW/networkcfg.conf .
	cp /root/eGW/vtyshLogCfg.txt .
	cp /root/eGW/ha.conf .
	cp /root/eGW/eGWLogCfg.txt .
	mkdir -p OMC
	cp -f /root/eGW/OMC/eGW_Monitor_Cfg_Info.xml OMC/.
	cp -f /root/eGW/OMC/eGW_Cfg_Info.xml OMC/.
	cp /root/eGW/OMC/config/app.conf OMC/.
	cp /root/eGW/nginx/nginx_wcg.conf .
	cp /root/eGW/redis/redis_wcg.conf .
else
	echo "Please input "$0" wcg or "$0" ipsec"
fi
