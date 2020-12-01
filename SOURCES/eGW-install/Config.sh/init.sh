#!/bin/bash -
#########################################################################################
# init.sh
# version:4.1
# update:20181023
#########################################################################################
redisPass=`cat /root/eGW/redis/redis_wcg.conf | awk '/^requirepass/{print $2}'`
function init_fold() {
    [[ ! -d /root/eGW/CDR/cdrDat ]] && mkdir -p /root/eGW/CDR/cdrDat
    [[ ! -d /root/eGW/ImsiFiles ]] && mkdir -p /root/eGW/ImsiFiles
    [[ ! -d /root/eGW/Logs/history ]] && mkdir -p /root/eGW/Logs/history
    [[ ! -d /root/eGW/Logs/keepalived ]] && mkdir -p /root/eGW/Logs/keepalived
    [[ ! -d /root/eGW/Logs/ltegwd ]] && mkdir -p /root/eGW/Logs/ltegwd
    [[ ! -d /root/eGW/Logs/sctpd ]] && mkdir -p /root/eGW/Logs/sctpd
    [[ ! -d /root/eGW/Logs/tcpdump ]] && mkdir -p /root/eGW/Logs/tcpdump
    [[ ! -d /root/eGW/Logs/vtysh ]] && mkdir -p /root/eGW/Logs/vtysh
    [[ ! -d /root/eGW/Logs/watchdog ]] && mkdir -p /root/eGW/Logs/watchdog
    [[ ! -d /root/eGW/Logs/omcapi/manage ]] && mkdir -p /root/eGW/Logs/omcapi/manage
    [[ ! -d /root/eGW/Logs/omcapi/monitor ]] && mkdir -p /root/eGW/Logs/omcapi/monitor
    [[ ! -d /root/eGW/Logs/omcapi/report ]] && mkdir -p /root/eGW/Logs/omcapi/report
}

function init_net() {
    if [[ -f /root/eGW/networkcfg.conf ]];then
        while read line
        do
            if [[ "${line:0:1}" != "#" ]]; then
                [[ -z "$line" ]] && continue
                $line 2>&1>/dev/null
            fi
        done < /root/eGW/networkcfg.conf
    fi
}

function init_redis() {
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' /root/eGW/ha.conf)
    local ha_local=$(awk -F ' = ' '/^localip/{print $2}' /root/eGW/ha.conf)
    if [[ $ha_switch == "enable" ]];then
        if [[ $ha_local ]];then
            grep "^bind 127.0.0.1 $ha_local" /root/eGW/redis/redis_wcg.conf
            if [[ $? == 1 ]];then
                sed -i "s@^bind .*@bind 127.0.0.1 $ha_local@g" /root/eGW/redis/redis_wcg.conf
                systemctl restart redis_wcg
            fi
        fi
    else
        grep "^bind 127.0.0.1" /root/eGW/redis/redis_wcg.conf
        if [[ $? == 1 ]];then
            sed -i "s@^bind .*@bind 127.0.0.1@g" /root/eGW/redis/redis_wcg.conf
            systemctl restart redis_wcg
        fi
    fi
    #local redis_pid=$(pidof redis-server)
    local redis_wcg_pid=$(ps -ef | grep redis-server | grep 9736 | awk '{print $2}')
    [[ $redis_wcg_pid ]] || systemctl restart redis_wcg
    while :
    do
		if [[ $redisPass ]]; then
			local redis_wcg_status=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass ping)
		else
			local redis_wcg_status=$(redis-cli -h 127.0.0.1 -p 9736 ping)
		fi
        if [[ $redis_wcg_status == "PONG" ]];then
            break
        fi
        #usleep 100000
    done
	if [[ $redisPass ]]; then
		redis-cli -h 127.0.0.1 -p 9736 -a $redisPass bgrewriteaof	
	else
		redis-cli -h 127.0.0.1 -p 9736 bgrewriteaof	
	fi
}

function init_nginx() {
    [[ ! -d /root/eGW/nginx/conf.d ]] && mkdir -p /root/eGW/nginx/conf.d
    [[ ! -d /root/eGW/nginx/default.d ]] && mkdir -p /root/eGW/nginx/default.d
    [[ ! -d /root/eGW/nginx/log ]] && mkdir -p /root/eGW/nginx/log
    systemctl restart nginx_wcg
}

function init_para() {
    if [[ -f /root/eGW/.para.init ]];then
		if [[ $redisPass ]]; then
			redis-cli -h 127.0.0.1 -p 9736 -a $redisPass del eGW-para-default
		else
			redis-cli -h 127.0.0.1 -p 9736 del eGW-para-default
		fi
        while read line
        do
            if [[ "${line:0:1}" != "#" ]]; then
                [[ -z "$line" ]] && continue
                key=$(echo $line | awk '{print $1}')
                value=$(echo $line | awk '{print $3}')
                #redis-cli del eGW-para-default
				if [[ $redisPass ]]; then
                	redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-para-default $key $value
				else
                	redis-cli -h 127.0.0.1 -p 9736 hset eGW-para-default $key $value
				fi

            fi	
        done < /root/eGW/.para.init
    fi
}

function read_para() {
	if [[ $redisPass ]]; then
		IPSEC_UPLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_ipsec_uplink_switch)
		IPSEC_UPLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-set config_ipsec_uplink_switch)
		IPSEC_DOWNLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_ipsec_downlink_switch)
		IPSEC_DOWNLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-set config_ipsec_downlink_switch)
		#IPTABLES_SWITCH_DEFAULT=$(redis-cli hget eGW-para-default config_iptables_switch)
		#IPTABLES_SWITCH_SET=$(redis-cli hget eGW-para-set config_iptables_switch)
		#IPTABLES_IF_DEFAULT=$(redis-cli hget eGW-para-default config_iptables_interface)
		#IPTABLES_IF_SET=$(redis-cli hget eGW-para-set config_iptables_interface)
		LF_SWITCH_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_gtp_forward_switch)
		LF_SWITCH_SET=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-set config_gtp_forward_switch)
		#LF_SWITCH_SET=$(awk '/switch/{print $3}' /root/eGW/localforwardnat.conf)
		LF_GTP_ADDR_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_gtp_address)
		#LF_GTP_ADDR_SET=$(redis-cli hget eGW-para-set config_gtp_address)
		[[ ! -f /root/eGW/.localforwardnat.conf ]] && touch /root/eGW/.localforwardnat.conf
		LF_GTP_ADDR_SET=$(awk '/gtpip/{print $3}' /root/eGW/localforwardnat.conf)
		LF_GTP_NAT_IF_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_gtp_nat_interface)
		#LF_GTP_NAT_IF_SET=$(redis-cli hget eGW-para-set config_gtp_nat_interface)
		LF_GTP_NAT_IF_SET=$(awk '/devname/{print $3}' /root/eGW/localforwardnat.conf)
		LF_GTP_NAT_ADDR_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-para-default config_gtp_nat_address)
		#LF_GTP_NAT_ADDR_SET=$(redis-cli hget eGW-para-set config_gtp_nat_address)
		LF_GTP_NAT_ADDR_SET=$(awk '/sourceip/{print $3}' /root/eGW/localforwardnat.conf)
	else
		IPSEC_UPLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_ipsec_uplink_switch)
		IPSEC_UPLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-set config_ipsec_uplink_switch)
		IPSEC_DOWNLINK_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_ipsec_downlink_switch)
		IPSEC_DOWNLINK_SET=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-set config_ipsec_downlink_switch)
		#IPTABLES_SWITCH_DEFAULT=$(redis-cli hget eGW-para-default config_iptables_switch)
		#IPTABLES_SWITCH_SET=$(redis-cli hget eGW-para-set config_iptables_switch)
		#IPTABLES_IF_DEFAULT=$(redis-cli hget eGW-para-default config_iptables_interface)
		#IPTABLES_IF_SET=$(redis-cli hget eGW-para-set config_iptables_interface)
		LF_SWITCH_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_gtp_forward_switch)
		LF_SWITCH_SET=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-set config_gtp_forward_switch)
		#LF_SWITCH_SET=$(awk '/switch/{print $3}' /root/eGW/localforwardnat.conf)
		LF_GTP_ADDR_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_gtp_address)
		#LF_GTP_ADDR_SET=$(redis-cli hget eGW-para-set config_gtp_address)
		[[ ! -f /root/eGW/.localforwardnat.conf ]] && touch /root/eGW/.localforwardnat.conf
		LF_GTP_ADDR_SET=$(awk '/gtpip/{print $3}' /root/eGW/localforwardnat.conf)
		LF_GTP_NAT_IF_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_gtp_nat_interface)
		#LF_GTP_NAT_IF_SET=$(redis-cli hget eGW-para-set config_gtp_nat_interface)
		LF_GTP_NAT_IF_SET=$(awk '/devname/{print $3}' /root/eGW/localforwardnat.conf)
		LF_GTP_NAT_ADDR_DEFAULT=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-para-default config_gtp_nat_address)
		#LF_GTP_NAT_ADDR_SET=$(redis-cli hget eGW-para-set config_gtp_nat_address)
		LF_GTP_NAT_ADDR_SET=$(awk '/sourceip/{print $3}' /root/eGW/localforwardnat.conf)
	fi

}

function start_ipsec() {
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    local ipsec_downlink_default=${IPSEC_DOWNLINK_DEFAULT:-"disable"}
    local ipsec_downlink_set=${IPSEC_DOWNLINK_SET}
    local ipsec_downlink=${ipsec_downlink_set:-$ipsec_downlink_default}
    local ha_switch=$(awk -F ' = ' '/^ha_switch/{print $2}' /root/eGW/ha.conf)
    if [[ ! -f /root/eGW/.ha.status ]];then
        echo "MASTER" > /root/eGW/.ha.status
    fi
    local ha_status=$(cat /root/eGW/.ha.status)
    if [[ $ha_switch == "enable" ]];then
        if [[ $ha_status == "MASTER" ]];then
            if [[ $ipsec_uplink == "enable" ]] || [[ $ipsec_downlink == "enable" ]];then
                ipsec start
            fi
        else
        	ipsec stop
        fi
    else
        if [[ $ipsec_uplink == "enable" ]] || [[ $ipsec_downlink == "enable" ]];then
            ipsec start
        fi
    fi
}

function init() {
    init_fold
    init_net
    init_redis
    init_nginx
    init_para
    read_para
    start_ipsec
}

