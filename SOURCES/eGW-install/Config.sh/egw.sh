#!/bin/bash -
#########################################################################################
# egw.sh
# version:6.1
# update:20181116
#########################################################################################
redisPass=`cat /root/eGW/redis/redis_wcg.conf | awk '/^requirepass/{print $2}'`
function ip2num()
{
		local CDIR=/root/eGW/Config.sh/.config  
		[[ ! -d $CDIR ]] && mkdir -p $CDIR
		ip_tmp=$1
		a=`echo $ip_tmp | awk -F'.' '{print $1}'`  
		b=`echo $ip_tmp | awk -F'.' '{print $2}'`
		c=`echo $ip_tmp | awk -F'.' '{print $3}'`
		d=`echo $ip_tmp | awk -F'.' '{print $4}'`

		printf %.2x $d >> $CDIR/ip.txt
		printf %.2x $c >> $CDIR/ip.txt
		printf %.2x $b >> $CDIR/ip.txt
		printf %.2x $a >> $CDIR/ip.txt
}
function ipsec_ipaddr() {
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
	if [[ $redisPass ]];then
			local ipsec_uplink_flag=$(redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hget eGW-status eGW-ipsec-state-uplink)
	else
			local ipsec_uplink_flag=$(redis-cli -h 127.0.0.1 -p 9736 hget eGW-status eGW-ipsec-state-uplink)
	fi
    local CDIR=/root/eGW/Config.sh/.config
    [[ ! -d $CDIR ]] && mkdir -p $CDIR
    if [[ $ipsec_uplink == "enable" ]] && [[ $ipsec_uplink_flag != "1" ]];then
        while :
        do
            #ip_ipsec="5.5.5.5"
            ip_ipsec=`ipsec status | grep client | grep === | awk '{print $2}' | awk 'BEGIN {FS = "/"} {print $1}'`
            if [[ -n "$ip_ipsec" ]];then
                break
            fi
            sleep 2
        done
		if [[ $redisPass ]];then 
				redis-cli -p 9736 -a $redisPass HGETALL egwActualRelayLocalStore > $CDIR/relay_show_tmp.txt
				redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ipsec-state-uplink 1
		else 
				redis-cli -p 9736 HGETALL egwActualRelayLocalStore > $CDIR/relay_show_tmp.txt
				redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ipsec-state-uplink 1
		fi
        /root/eGW/Tools/egwTool -P > $CDIR/config.save
        echo "ip_ipsec "$ip_ipsec >> $CDIR/config.save 
		local work_mode=$(awk '/workmode/{print $3}' $CDIR/config.save)
        local cp_ip=$(awk '/macro-enblink/{print $5}' $CDIR/config.save)
        local up_ip=$(awk '/gtpu-uplink/{print $3}' $CDIR/config.save)
		echo -n "ipsec_ip_hex " > $CDIR/ip.txt
		ip2num $ip_ipsec
		echo " " >> $CDIR/ip.txt

        local ip_conf=$ip_ipsec
		if [[ $work_mode == "standard" ]];then
        	for ip in $cp_ip
        	do
            	/root/eGW/Tools/egwTool -P | \
            	awk -v ip=$ip -v ip_conf=$ip_conf '{if($1~/macro-enblink/ && $5==ip){system("/root/eGW/Tools/egwTool -S eNB_Link:"$3":"$4":1:"ip_conf":"$6":"$7":"$8);exit}}'
        	done
        elif [[ $work_mode == "relay" ]];then
			ipsec_ip_hex=$(awk '/ipsec_ip_hex/{print $2}' $CDIR/ip.txt)
			local tmp_line="00000000:00000"
			while read line
			do 
				if [[ "$tmp_line" != "$line" ]];then
					tmp_array=(`echo $line | sed 's/:/ /' | cut -d ' ' -f 1,2`)
					if [[ "$ipsec_ip_hex" != "${tem_array[0]}" ]];then
						if [[ $redisPass ]]; then
								redis-cli -p 9736 -a $redisPass -c hdel egwActualRelayLocalStore "${tmp_array[0]}:${tmp_array[1]}"
								redis-cli -p 9736 -a $redisPass -c hset egwActualRelayLocalStore "$ipsec_ip_hex:${tmp_array[1]}" "$ipsec_ip_hex:${tmp_array[1]}"
						else
								redis-cli -p 9736 -c hdel egwActualRelayLocalStore "${tmp_array[0]}:${tmp_array[1]}"
								redis-cli -p 9736 -c hset egwActualRelayLocalStore "$ipsec_ip_hex:${tmp_array[1]}" "$ipsec_ip_hex:${tmp_array[1]}"
						fi

					fi
				fi
				tmp_line=$line
			done < $CDIR/relay_show_tmp.txt
		fi

        num=0
        for ip in $up_ip
        do
            num=$((num+1))
            /root/eGW/Tools/egwTool -P | \
            awk -v ip=$ip -v ip_conf="$ip_conf" -v num=$num '{if($1~/gtpu-uplink/ && $3==ip){system("/root/eGW/Tools/egwTool -S GTPU:"num":1:2:"ip_conf);exit}}'
        done
        pkill ltegwd && /root/eGW/ltegwd 0 1 &
    elif [[ $ipsec_uplink == "disable" ]] && [[ $ipsec_uplink_flag == "1" ]];then
        local ip_conf=$(cat $CDIR/config.save | awk '/ip_ipsec/{print $2}')
        [[ ! $(ipsec status) ]] && ipsec start && sleep 2
        local cp_ip=$(awk '/macro-enblink/{print $5}' $CDIR/config.save)
        local up_ip=$(awk '/gtpu-uplink/{print $3}' $CDIR/config.save)
		local work_mode=$(awk '/workmode/{print $3}' $CDIR/config.save)
		if [[ $work_mode == "standard" ]];then
        	for ip in $cp_ip
        	do
        	    /root/eGW/Tools/egwTool -P | \
            	awk -v ip=$ip_conf -v ip_conf=$ip '{if($1~/macro-enblink/ && $5==ip){system("/root/eGW/Tools/egwTool -S eNB_Link:"$3":"$4":1:"ip_conf":"$6":"$7":"$8);exit}}'
        	done
		elif [[ $work_mode == "relay" ]];then
			ipsec_ip_hex=$(awk '/ipsec_ip_hex/{print $2}' $CDIR/ip.txt)
			local tmp_line="00000000:00000"
			while read line
			do 
				if [[ "$tmp_line" != "$line" ]];then
					tmp_array=(`echo $line | sed 's/:/ /' | cut -d ' ' -f 1,2`)
					if [[ "$ipsec_ip_hex" != "${tem_array[0]}" ]];then 
						if [[ $redisPass ]]; then
								redis-cli -p 9736 -a $redisPass -c hdel egwActualRelayLocalStore "$ipsec_ip_hex:${tmp_array[1]}"
								redis-cli -p 9736 -a $redisPass -c hset egwActualRelayLocalStore "${tmp_array[0]}:${tmp_array[1]}" "${tmp_array[0]}:${tmp_array[1]}"
						else
								redis-cli -p 9736 -c hdel egwActualRelayLocalStore "$ipsec_ip_hex:${tmp_array[1]}"
								redis-cli -p 9736 -c hset egwActualRelayLocalStore "${tmp_array[0]}:${tmp_array[1]}" "${tmp_array[0]}:${tmp_array[1]}"
						fi
					fi  
				fi  
				tmp_line=$line
			done < $CDIR/relay_show_tmp.txt
		fi
        num=0
        for ip in $up_ip
        do
            num=$((num+1))
            /root/eGW/Tools/egwTool -P | \
            awk -v ip=$ip_conf -v ip_conf=$ip -v num=$num '{if($1~/gtpu-uplink/ && $3==ip){system("/root/eGW/Tools/egwTool -S GTPU:"num":1:2:"ip_conf);exit}}'
        done
		if [[ $redisPass ]] ;then 
				redis-cli -h 127.0.0.1 -p 9736 -a $redisPass hset eGW-status eGW-ipsec-state-uplink 0
		else
				redis-cli -h 127.0.0.1 -p 9736 hset eGW-status eGW-ipsec-state-uplink 0
		fi
        pkill ltegwd && /root/eGW/ltegwd 0 1 &
    fi
}

function init_gso() {
    local CDIR=/root/eGW/Config.sh/.config
    [[ ! -d $CDIR ]] && mkdir -p $CDIR
    echo "show running-config" > $CDIR/gso.show
    local ipaddr_toepc=$(/root/eGW/vtysh -c $CDIR/gso.show |grep "macro-enblink add " | awk 'NR==1{print $5}')
    local ipaddr_toenb=$(/root/eGW/vtysh -c $CDIR/gso.show | awk '/home-enb accessip/{print $4;exit}')
    if [[ $ipaddr_toepc ]];then
        local inet_toepc=$(ifconfig -a | grep $ipaddr_toepc -B 1 | head -1 | cut -d " " -f 1 | sed 's/.$//')
        [[ $inet_toepc ]] && ethtool -K $inet_toepc gso off 
    fi
    if [[ $ipaddr_toenb ]];then
        local inet_toenb=$(ifconfig -a | grep $ipaddr_toenb -B 1 | head -1 | cut -d " " -f 1 | sed 's/.$//')
        [[ $inet_toenb ]] && ethtool -K $inet_toenb gso off
    fi
}


function gtp() {
    local lf_switch_default=${LF_SWITCH_DEFAULT:-"disable"}
    #local lf_switch_set=${LF_SWITCH_SET}
    local lf_switch_set=$(cat /root/eGW/localforwardnat.conf | awk '/switch/{print $3}')
    local lf_switch=${lf_switch_set:-$lf_switch_default}
    local gtp_addr_default=${LF_GTP_ADDR_DEFAULT}
    #local gtp_addr_set=${LF_GTP_ADDR_SET}
    local gtp_addr_set=$(cat /root/eGW/localforwardnat.conf | awk '/gtpip/{print $3}')
    local gtp_addr=${gtp_addr_set:-$gtp_addr_default}
    local gtp_a=$(echo $gtp_addr | awk -F '.' '{print $1}')
    local gtp_b=$(echo $gtp_addr | awk -F '.' '{print $2}')
    local gtp_nat_if_default=${LF_GTP_NAT_IF_DEFAULT}
    #local gtp_nat_if_set=${LF_GTP_NAT_IF_SET}
    local gtp_nat_if_set=$(cat /root/eGW/localforwardnat.conf | awk '/devname/{print $3}')
    local gtp_nat_if=${gtp_nat_if_set:-$gtp_nat_if_default}
    local gtp_nat_addr_default=${LF_GTP_NAT_ADDR_DEFAULT}
    #local gtp_nat_addr_set=${LF_GTP_NAT_ADDR_SET}
    local gtp_nat_addr_set=$(cat /root/eGW/localforwardnat.conf | awk '/sourceip/{print $3}')
    local gtp_nat_addr=${gtp_nat_addr_set:-$gtp_nat_addr_default}
    if [[ $lf_switch == "enable" ]];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_all_lbo
        [[ $gtp_addr ]] && ifconfig gtp1_1 $gtp_addr 
        if [[ $gtp_a ]] && [[ $gtp_b ]];then
            var=`expr $gtp_a \* 256 + $gtp_b`
            echo $var > /sys/module/gtp_relay/parameters/gtp_lip_prefix
            if [[ $gtp_nat_if ]] && [[ $gtp_nat_addr ]];then
                local CDIR=/root/eGW/Config.sh/.config
                [[ ! -d $CDIR ]] && mkdir -p $CDIR
                if [[ -f $CDIR/iptables.cmd ]];then
                    sed -i 's/-A/-D/' $CDIR/iptables.cmd
                    iptables_set=$(cat $CDIR/iptables.cmd)
                    $iptables_set 2>&1>/dev/null
                fi		
                local iptables_cmd="iptables -t nat -A POSTROUTING -s ${gtp_a}.${gtp_b}.0.0/16 -o $gtp_nat_if -j SNAT --to-source $gtp_nat_addr"
                $iptables_cmd && echo $iptables_cmd > $CDIR/iptables.cmd
            fi
        fi
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_all_lbo
        iptables -t nat -D POSTROUTING -s ${gtp_a}.${gtp_b}.0.0/16 -o $gtp_nat_if -j SNAT --to-source $gtp_nat_addr &>/dev/null
    fi
    local ipsec_uplink_default=${IPSEC_UPLINK_DEFAULT:-"disable"}
    local ipsec_uplink_set=${IPSEC_UPLINK_SET}
    local ipsec_uplink=${ipsec_uplink_set:-$ipsec_uplink_default}
    local ipsec_downlink_default=${IPSEC_DOWNLINK_DEFAULT:-"disable"}
    local ipsec_downlink_set=${IPSEC_DOWNLINK_SET}
    local ipsec_downlink=${ipsec_downlink_set:-$ipsec_downlink_default}
    if [[ $ipsec_downlink == "enable" ]];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_ipsec_dl
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_ipsec_dl
    fi
    if [[ $ipsec_uplink == "enable" ]];then
        echo 1 > /sys/module/gtp_relay/parameters/gtp_ipsec_ul
    else
        echo 0 > /sys/module/gtp_relay/parameters/gtp_ipsec_ul
    fi
}

function egw() {
#ipsec_ipaddr
    init_gso
    #gtp
}
