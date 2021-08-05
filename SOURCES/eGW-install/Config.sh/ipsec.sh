#!/bin/bash -
#########################################################################################
# ipsec.sh
# version:6.0
# update:20210805
#########################################################################################
IPSEC_DIR="/usr/lib/eGW/IPSEC"

function check_ip() {
    IP=$1
    ip_check=$(echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
    if [[ -z $ip_check ]];then
        echo "IP address must be 1-3 digits!"
        exit 1
    fi
    ipaddr=$1
    a=`echo $ipaddr|awk -F . '{print $1}'`
    b=`echo $ipaddr|awk -F . '{print $2}'`
    c=`echo $ipaddr|awk -F . '{print $3}'`
    d=`echo $ipaddr|awk -F . '{print $4}'`
    for num in $a $b $c $d
    do
        if [ $num -gt 255 ] || [ $num -lt 0 ];then
            echo "$ipaddr,the field $num is error!"
            exit 1
        fi
    done
}

function init_fold() {
    [[ ! -d $IPSEC_DIR/ipxs_bak ]] && mkdir -p $IPSEC_DIR/ipxs_bak
}

function add_ipxs() {
    [[ $(ls $IPSEC_DIR/*.ipxs) ]] 2>/dev/null && mv -f $IPSEC_DIR/*.ipxs $IPSEC_DIR/ipxs_bak
    ipsec status &>/dev/null || return 1
    local add_ip=$(ipsec status | awk '/===/{print $4}' | awk -F '/' '{print $1}')
    if [[ $add_ip ]];then
        for ip in $add_ip
        do
            local spis_i=$(ipsec status | grep "$ip" -B1 | awk '/SPIs/{print $8}' | awk -F '_' '{print $1}')
            local spis_o=$(ipsec status | grep "$ip" -B1 | awk '/SPIs/{print $9}' | awk -F '_' '{print $1}')
            local ipxs_i=$(ip xfrm state | grep "spi 0x$spis_i" -B1 -A3)
            local ipxs_o=$(ip xfrm state | grep "spi 0x$spis_o" -B1 -A3)
            local src_i=$(echo $ipxs_i | awk '{print $2}')
            local dst_i=$(echo $ipxs_i | awk '{print $4}')
            echo $ipxs_o > $IPSEC_DIR/$src_i-$dst_i-$ip-$spis_i-$spis_o.ipxs
            echo $ipxs_i >> $IPSEC_DIR/$src_i-$dst_i-$ip-$spis_i-$spis_o.ipxs
        done
    fi
}

function del_ipxs() {
    ipxs_num=$1
    ls -lt $IPSEC_DIR/ipxs_bak/*.ipxs 2>/dev/null | awk -v ipxs_num=$ipxs_num '{if(NR>ipxs_num){print $9}}' | xargs rm -rf
}

function ipsec_ipxs() {
    init_fold
    add_ipxs
    del_ipxs 10000
}

function parse_ipxs() {
    local field=$1
    local type=$2
    local ip=$3
    if [[ $type == "ipsecip" ]] && [[ $ip ]];then
        local ipsec_ip=$ip
        local spis_i=$(ipsec status | \
        grep "$ipsec_ip" -B1 | awk '/SPIs/{print $8}' | awk -F '_' '{print $1}')		
        local spis_o=$(ipsec status | \
        grep "$ipsec_ip" -B1 | awk '/SPIs/{print $9}' | awk -F '_' '{print $1}')
    elif [[ $type == "sourceip" ]] && [[ $ip ]];then
        local source_ip=$ip
        local ipsec_ip=$(ipsec status | \
        grep "$source_ip" -A2 | awk '/===/{print $4}' | awk -F '/' '{print $1}')
        local spis_i=$(ipsec status | \
        grep "$source_ip" -A1 | awk '/SPIs/{print $8}' | awk -F '_' '{print $1}') 
        local spis_o=$(ipsec status | \
        grep "$source_ip" -A1 | awk '/SPIs/{print $9}' | awk -F '_' '{print $1}')
    elif [[ $type == "localip" ]];then
        local ipsec_ip=$(ipsec status | awk '/===/{print $4}' | awk -F '/' '{print $1}')
    else
        exit 1
    fi
    local ipxs_i=$(ip xfrm state | grep "spi 0x$spis_i" -B1 -A3)
    local ipxs_o=$(ip xfrm state | grep "spi 0x$spis_o" -B1 -A3)
    #local src_i=$(echo $ipxs_i | awk '{print $2}')
    #local src_o=$(echo $ipxs_o | awk '{print $2}')
    #local dst_i=$(echo $ipxs_i | awk '{print $4}')
    #local dst_o=$(echo $ipxs_o | awk '{print $4}')
    #local spi_i=$(echo $ipxs_i | awk '{print $8}')
    #local spi_o=$(echo $ipxs_o | awk '{print $8}')
    #local auth_trunc_a_i=$(echo $ipxs_i | awk '{print $18}')
    #local auth_trunc_k_i=$(echo $ipxs_i | awk '{print $19}')
    #local auth_trunc_n_i=$(echo $ipxs_i | awk '{print $20}')
    #local auth_trunc_a_o=$(echo $ipxs_o | awk '{print $18}')
    #local auth_trunc_k_o=$(echo $ipxs_o | awk '{print $19}')
    #local auth_trunc_n_o=$(echo $ipxs_o | awk '{print $20}')
    #local enc_a_i=$(echo $ipxs_i | awk '{print $22}')
    #local enc_k_i=$(echo $ipxs_i | awk '{print $23}')
    #local enc_a_o=$(echo $ipxs_o | awk '{print $22}')
    #local enc_k_o=$(echo $ipxs_o | awk '{print $23}')
    case "$field" in
        src_i)
            local src_i=$(echo $ipxs_i | awk '{print $2}')
            [[ $src_i ]] && echo $src_i;;
        src_o)
            local src_o=$(echo $ipxs_o | awk '{print $2}')
            [[ $src_o ]] && echo $src_o;;
        dst_i)
            local dst_i=$(echo $ipxs_i | awk '{print $4}')
            [[ $dst_i ]] && echo $dst_i;;
        dst_o)
            local dst_o=$(echo $ipxs_o | awk '{print $4}')
            [[ $dst_o ]] && echo $dst_o;;
        ipsec_ip)
            [[ $ipsec_ip ]] && echo $ipsec_ip;;
        spi_i)
            local spi_i=$(echo $ipxs_i | awk '{print $8}')
            [[ $spi_i ]] && echo $spi_i;;
        spi_o)
            local spi_o=$(echo $ipxs_o | awk '{print $8}')
            [[ $spi_o ]] && echo $spi_o;;
        auth_trunc_a_i)
            local auth_trunc_a_i=$(echo $ipxs_i | awk '{print $18}')
            [[ $auth_trunc_a_i ]] && echo $auth_trunc_a_i;;
        auth_trunc_a_o)
            local auth_trunc_a_o=$(echo $ipxs_o | awk '{print $18}')
            [[ $auth_trunc_a_o ]] && echo $auth_trunc_a_o;;
        auth_trunc_k_i)
            local auth_trunc_k_i=$(echo $ipxs_i | awk '{print $19}')
            [[ $auth_trunc_k_i ]] && echo $auth_trunc_k_i;;
        auth_trunc_k_o)
            local auth_trunc_k_o=$(echo $ipxs_o | awk '{print $19}')
            [[ $auth_trunc_k_o ]] && echo $auth_trunc_k_o;;
        auth_trunc_n_i)
            local auth_trunc_n_i=$(echo $ipxs_i | awk '{print $20}')
            [[ $auth_trunc_n_i ]] && echo $auth_trunc_n_i;;
        auth_trunc_n_o)
            local auth_trunc_n_o=$(echo $ipxs_o | awk '{print $20}')
            [[ $auth_trunc_n_o ]] && echo $auth_trunc_n_o;;
        enc_a_i)
            local enc_a_i=$(echo $ipxs_i | awk '{print $22}')
            [[ $enc_a_i ]] && echo $enc_a_i;;
        enc_a_o)
            local enc_a_o=$(echo $ipxs_o | awk '{print $22}')
            [[ $enc_a_o ]] && echo $enc_a_o;;
        enc_k_i)
            local enc_k_i=$(echo $ipxs_i | awk '{print $23}')
            [[ $enc_k_i ]] && echo $enc_k_i;;
        enc_k_o)
            local enc_k_o=$(echo $ipxs_o | awk '{print $23}')
            [[ $enc_k_o ]] && echo $enc_k_o;;
        ipxs_i)
            [[ $ipxs_i ]] && echo $ipxs_i;;
        ipxs_o)
            [[ $ipxs_o ]] && echo $ipxs_o;;
        ipxs)
            ip xfrm state | grep "spi 0x$spis_i" -B1 -A3
            ip xfrm state | grep "spi 0x$spis_o" -B1 -A3
            #[[ $ipxs_o ]] && echo $ipxs_o
            #[[ $ipxs_i ]] && echo $ipxs_i;;
    esac    
}

#[[ $1 ]] && [[ $2 ]] && parse_ipxs $1 $2

ARGS=`getopt -o hvi:p:ls: --long help,version,ipsecip:,parse:,list,sourceip: -- "$@"`
if [ $? != 0 ] ; then /root/eGW/Config.sh/ipsec.sh -h ; exit 1 ; fi
eval set -- "$ARGS"
while true
do
    case "$1" in
        -i|--ipsecip)
            ipsec_ip=$2
            check_ip $ipsec_ip
            flag=`ipsec status | awk '/===/{print $2  $3 $4}'| grep $ipsec_ip`
            if [[ -z $flag ]]; then
                echo "No ipsec tunnel built with this ipsec IP!"
                exit
            fi
            shift 2;;
        -p|--parse)
            if [[ $ipsec_ip ]];then
                parse_ipxs "$2" "ipsecip" $ipsec_ip
            elif [[ $source_ip ]];then
                parse_ipxs "$2" "sourceip" $source_ip
            fi
            shift 2;;
        -l|--list)
            parse_ipxs "ipsec_ip" "localip"
            shift;;
        -s|--sourceip)
            source_ip=$2
            check_ip $source_ip
            flag1=`ipsec status | awk '/ESTABLISHED/{print $6}'| grep $source_ip`
            if [[ -z $flag1 ]]; then
                echo "No ipsec tunnel built with this source IP!"
                exit
            fi
            shift 2;;
        -v|--version)
            echo "version: 1.0"
            shift;;
        -h|--help)
            echo "***************************************************************************************************"
            echo "usage:"
            echo ""
            echo "  ipsec -h|-v|-i [ipaddr] -p [field]|-s [ipaddr] -p [field]"
            echo ""
            echo "  -h|--help                                         list help information"
            echo "  -v|--version                                      list released version"           
            echo "  -l|--list                                         list all ipsec ip"			
            echo "  -i|--ipsecip [ipaddr] -p|--parse [field]          parse field by ipsec ip"
            echo "  -s|--sourceip [ipaddr] -p|--parse [field]         parse field by source ip"
            echo ""
            echo "  field:"
            echo "        ipsec_ip"
            echo "        src_i|src_o|dst_i|dst_o"
            echo "        spi_i|spi_o"
            echo "        auth_trunc_a_i|auth_trunc_a_o|auth_trunc_k_i|auth_trunc_k_o|auth_trunc_n_i|auth_trunc_n_o"
            echo "        enc_a_i|enc_a_o|enc_k_i|enc_k_o"
            echo "        ipxs_i|ipxs_o|ipxs"
            echo "***************************************************************************************************"
            shift;;
	    --)
            shift
            break;;
        *) 
            echo "unknown:{$1}"
            exit 1;;
    esac
done
