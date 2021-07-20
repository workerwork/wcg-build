#制作WCG版本的spec文件

Name:       WCG
Version:    1.0.0
Release:    1%{?dist}
Summary:    WCG rpm package

License:    GPL
Packager:   dongfeng
#URL:            
Source0:    %{name}-%{version}.tar.gz
#patch0:
#BuildRequires:  
Requires:   nginx,redis,hiredis,fcgi,spawn-fcgi,gsoap,curl,lksctp-tools,vconfig,xinetd,tftp,tftp-server,keepalived,net-tools,ethtool     

%description
The rpm package for WCG install!


%prep
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/home/wcg/eGW
cp -arf . $RPM_BUILD_ROOT/home/wcg/eGW
#rm -rf $RPM_BUILD_ROOT/root/eGW/monitor.service
#rm -rf $RPM_BUILD_ROOT/root/eGW/om.service
#rm -rf $RPM_BUILD_ROOT/root/eGW/keepalived.conf
#rm -rf $RPM_BUILD_ROOT/root/eGW/OMC/nginx.conf
mkdir -p $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf monitor.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf OMC/om.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf redis/redis_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf nginx/nginx_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf keepalived/keepalived_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
#mkdir -p $RPM_BUILD_ROOT/etc/keepalived
#cp -rf keepalived.conf $RPM_BUILD_ROOT/etc/keepalived/keepalived.conf.wcg
#mkdir -p $RPM_BUILD_ROOT/etc/nginx
#cp -rf nginx.conf $RPM_BUILD_ROOT/etc/nginx/nginx.conf.wcg


%clean
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR
ls | grep -v git.init | xargs rm -rf

%files
%defattr(-,root,root,-)
%doc
#%config(noreplace) /root/eGW/config.conf
%config(noreplace) /home/wcg/eGW/lo.bin
%config(noreplace) /home/wcg/eGW/ls.bin
%config(noreplace) /home/wcg/eGW/networkcfg.conf
%config(noreplace) /home/wcg/eGW/ha.conf
%config(noreplace) /home/wcg/eGW/eGWLogCfg.txt
%config(noreplace) /home/wcg/eGW/OMC/eGW_Cfg_Info.xml
%config(noreplace) /home/wcg/eGW/OMC/config/app.conf
%config(noreplace) /home/wcg/eGW/vtyshLogCfg.txt
%config(noreplace) /home/wcg/eGW/OMC/eGW_Monitor_Cfg_Info.xml
%config(noreplace) /home/wcg/eGW/ltegwd.xml
%config(noreplace) /home/wcg/eGW/gotty.conf
#%config(noreplace) /root/eGW/keepalived.conf.wcg
#%config(noreplace) /root/eGW/nginx.conf.wcg
%config(noreplace) /home/wcg/eGW/redis/redis_wcg.conf
%config(noreplace) /home/wcg/eGW/nginx/nginx_wcg.conf
%config(noreplace) /home/wcg/eGW/keepalived/keepalived_wcg.conf
#%config(missingok) /home/wcg/eGW/keepalived.conf.wcg
#%config(missingok) /home/wcg/eGW/nginx.conf.wcg
/usr/lib/systemd/system/*
#/etc/keepalived/*
#/etc/nginx/*
/home/wcg/eGW
%exclude /home/wcg/eGW/monitor.service
%exclude /home/wcg/eGW/OMC/om.service
%exclude /home/wcg/eGW/redis/redis_wcg.service
%exclude /home/wcg/eGW/nginx/nginx_wcg.service
%exclude /home/wcg/eGW/keepalived/keepalived_wcg.service
%exclude /home/wcg/eGW/initWCGOS.sh
#%exclude /root/eGW/keepalived.conf
#%exclude /root/eGW/nginx.conf
#%ghost
#%verify[not]
#%docdir
#%dir

%changelog
* Thu Feb 08 2018 dongfeng <18510416169@qq.com> 本次版本0.0.1-1
- this is just a test for changelog!

#*****************************************************************************************#
%pre
#Description: This script is used to set system environment before install WCG.
#*****************************************************************************************#
#!/bin/bash

source /etc/init.d/functions

rpm_type=$1

#check kernel
function kernel_chk() {
    ver_std="3.10.0-1127c.el7.x86_64"
    ver_kernel=$(uname -r)
    if [[ $ver_kernel != $ver_std ]];then
        action "system kernel check" /bin/false
        #echo "system kernel must be $ver_std1 or $ver_std2, please check!"
        exit 1
    else
        action "system kernel check" /bin/true
    fi
}

function networkmanager_stop() {
    if [[ $rpm_type == 1 ]];then
        systemctl stop NetworkManager && systemctl disable NetworkManager
        (($? == 0)) && action "systemctl stop NetworkManager" /bin/true || \
        action "systemctl stop NetworkManager" /bin/false
    fi
}

function pre_WCG_ins() {
    echo "**Run the shell before WCG install..."	
    kernel_chk
    networkmanager_stop
}

pre_WCG_ins

#*****************************************************************************************#
%post
#Description: This script is used to set system environment after install WCG.
#*****************************************************************************************#
#!/bin/bash

source /etc/init.d/functions

rpm_type=$1
DIR=/root/eGW
[[ -d /root/eGW  ]] && rm -rf /root/eGW
ln -sf /home/wcg/eGW /root/eGW

#add exec for WCG-files
#function WCG_addx() {
#    cd $DIR
#    chmod +x startAll.sh
#    chmod +x ltegwd
#    chmod +x vtysh
#    chmod +x vman
#    chmod +x update
#    chmod +x ${DIR}/Tools/*
#    chmod +x ${DIR}/Config.sh/*.sh
#    chmod +x ${DIR}/OMC/egw_manage
#    chmod +x ${DIR}/OMC/egw_report
#    chmod +x ${DIR}/OMC/egw_manage_logger
#    chmod +x ${DIR}/OMC/egw_monitor
#    chmod +x ${DIR}/OMC/egw_om
#    chmod +x ${DIR}/OMC/startOm.sh
#    chmod +x ${DIR}/OMC/stopOm.sh
#    chmod +x ${DIR}/Licence/register
	
#    action "chmod +x *" /bin/true
#}

#register WCG and enable service
function WCG_reg() {
    #cd ${DIR}/Licence
    #${DIR}/Licence/register
    systemctl daemon-reload
    systemctl enable monitor.service
    (($? == 0)) && action "systemctl enable monitor.service" /bin/true || \
    action "systemctl enable monitor.service" /bin/false
    systemctl enable om.service
    systemctl start om.service
    (($? == 0)) && action "systemctl enable/start om.service" /bin/true || \
    action "systemctl enable/start om.service" /bin/false
}

#config nginx
#function nginx_cfg() {
    #[ ! -d "/usr/share/nginx/logs" ] && mkdir -p /usr/share/nginx/logs
    #LANG=C grep 'server_name eGW_omc' /etc/nginx/nginx.conf 2>&1>/dev/null || \
    #sed -i '/include \/etc\/nginx\/conf.d\/\*.conf;/r nginx_add.txt' /etc/nginx/nginx.conf
    #rm -rf ${DIR}/nginx_add.txt
    #systemctl enable nginx.service && systemctl restart nginx.service
    #(($? == 0)) && action "nginx start" /bin/true || \
    #action "nginx start" /bin/false
#}
#function nginx_cfg() {
    #if [[ $rpm_type == 1 ]];then
        #mv -f /root/eGW/nginx.conf.wcg /etc/nginx/nginx.conf
    #elif [[ $rpm_type == 2 ]];then
        #rm -rf /root/eGW/nginx.conf.wcg
    #fi
    #systemctl enable nginx_wcg.service && systemctl restart nginx_wcg.service
    #(($? == 0)) && action "nginx_wcg start" /bin/true || \
    #action "nginx_wcg start" /bin/false
#}

#config redis
#function redis_cfg() {
    #sed -i "s@.*\(appendonly[  ]\).*@\1yes@" /etc/redis.conf
    #sed -i "s@.*\(auto-aof-rewrite-min-size[  ]\).*@\15mb@" /etc/redis.conf
    #redis_pid=$(pidof redis-server)
    #[ $redis_pid ] && redis-cli bgrewriteaof
    #systemctl enable redis_wcg.service && systemctl restart redis_wcg.service
    #(($? == 0)) && action "redis_wcg start" /bin/true || \
    #action "redis_wcg start" /bin/false
#}

#config keepalived
#function keepalived_cfg() {
    #if [[ $rpm_type == 1 ]];then 
        #mv -f /root/eGW/keepalived.conf.wcg /etc/keepalived/keepalived.conf
    #elif [[ $rpm_type == 2 ]];then
        #rm -rf /root/eGW/keepalived.conf.wcg
    #fi
    #action "keepalived configure" /bin/true
#}

#set system environment
function system_env_set() {
    systemctl stop firewalld.service 
    systemctl disable firewalld.service
    ulimit -c unlimited
    setenforce 0
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g"  /etc/selinux/config
    [ ! -d "/var/opc/lc" ] && mkdir -p /var/opt/lc
    [ ! -d "/var/opc/mo" ] && mkdir -p /var/opt/mo
    action "system env configure" /bin/true
}

#set sysctl
function sysctl_set() {

    LANG=C grep "net.ipv4.ip_forward" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.ip_forward\).*/\1 = 1/g"  /etc/sysctl.conf || \
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.tcp_tw_reuse" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.tcp_tw_reuse\).*/\1 = 1/g" /etc/sysctl.conf || \
    echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.tcp_tw_recycle" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.tcp_tw_recycle\).*/\1 = 1/g" /etc/sysctl.conf || \
    echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.tcp_syncookies" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.tcp_syncookies\).*/\1 = 1/g" /etc/sysctl.conf || \
    echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.tcp_fin_timeout" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.tcp_fin_timeout\).*/\1 = 30/g" /etc/sysctl.conf || \
    echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
	
    LANG=C grep "net.ipv4.neigh.default.gc_thresh1" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.neigh.default.gc_thresh1\).*/\1 = 25000/g"  /etc/sysctl.conf || \
    echo "net.ipv4.neigh.default.gc_thresh1 = 25000" >> /etc/sysctl.conf
	
    LANG=C grep "net.ipv4.neigh.default.gc_thresh2" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.neigh.default.gc_thresh2\).*/\1 = 30000/g"  /etc/sysctl.conf || \
    echo "net.ipv4.neigh.default.gc_thresh2 = 30000" >> /etc/sysctl.conf
	
    LANG=C grep "net.ipv4.neigh.default.gc_thresh3" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.neigh.default.gc_thresh3\).*/\1 = 40000/g"  /etc/sysctl.conf || \
    echo "net.ipv4.neigh.default.gc_thresh3 = 40000" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.conf.all.rp_filter" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.conf.all.rp_filter\).*/\1 = 0/g"  /etc/sysctl.conf || \
    echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.conf.all.arp_ignore" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.conf.all.arp_ignore\).*/\1 = 1/g"  /etc/sysctl.conf || \
    echo "net.ipv4.conf.all.arp_ignore = 1" >> /etc/sysctl.conf

    LANG=C grep "net.ipv4.conf.all.arp_announce" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.conf.all.arp_announce\).*/\1 = 2/g"  /etc/sysctl.conf || \
    echo "net.ipv4.conf.all.arp_announce = 2" >> /etc/sysctl.conf

    local if_tmp=$(ifconfig -a | awk -F ':' '/flag/{if($1!="lo"&&$1!~/virbr/&&$1!~/docker/){print $1}}'| sort -u)
    for i in $if_tmp
    do
        LANG=C grep "net.ipv4.conf.${i}.rp_filter" /etc/sysctl.conf 2>&1>/dev/null && \
        sed -i "s/.*\(net.ipv4.conf.${i}.rp_filter\).*/\1 = 0/g"  /etc/sysctl.conf || \
        echo "net.ipv4.conf.${i}.rp_filter = 0" >> /etc/sysctl.conf
        LANG=C grep "net.ipv4.conf.${i}.arp_ignore" /etc/sysctl.conf 2>&1>/dev/null && \
        sed -i "s/.*\(net.ipv4.conf.${i}.arp_ignore\).*/\1 = 1/g"  /etc/sysctl.conf || \
        echo "net.ipv4.conf.${i}.arp_ignore = 1" >> /etc/sysctl.conf
        LANG=C grep "net.ipv4.conf.${i}.arp_announce" /etc/sysctl.conf 2>&1>/dev/null && \
        sed -i "s/.*\(net.ipv4.conf.${i}.arp_announce\).*/\1 = 2/g"  /etc/sysctl.conf || \
        echo "net.ipv4.conf.${i}.arp_announce = 2" >> /etc/sysctl.conf
    done

    LANG=C grep "kernel.msgmni" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(kernel.msgmni\).*/\1 = 8192/g"  /etc/sysctl.conf || \
    echo "kernel.msgmni = 8192" >> /etc/sysctl.conf

    LANG=C grep "kernel.msgmax" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(kernel.msgmax\).*/\1 = 32768/g"  /etc/sysctl.conf || \
    echo "kernel.msgmax = 32768" >> /etc/sysctl.conf

    LANG=C grep "kernel.msgmnb" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(kernel.msgmnb\).*/\1 = 4203520/g"  /etc/sysctl.conf || \
    echo "kernel.msgmnb = 4203520" >> /etc/sysctl.conf

    sysctl -p

    action "sysctl configure" /bin/true
}

#set coredump
function coredump_set() {
    #[[ -d "/home/wcg/coredump" ]] && rm -rf /home/wcg/coredump
    [ ! -d "/home/wcg/coredump" ] && mkdir -p /home/wcg/coredump && chmod 0773 /home/wcg/coredump
    [ -d "/root/coredump" ] && rm -rf /root/coredump
    ln -sf /home/wcg/coredump /root/coredump
    #[ ! -d "/root/coredump" ] && mkdir -p /root/coredump && chmod 0773 /root/coredump

    echo "kernel.core_pattern = /root/coredump/core-%e-sig%s-user%u-group%g-pid%p-time%t" > /etc/sysctl.d/core.conf
    echo "kernel.core_uses_pid = 1" >> /etc/sysctl.d/core.conf
    echo "fs.suid_dumpable = 2" >> /etc/sysctl.d/core.conf
    echo "*       hard        core        unlimited" > /etc/security/limits.d/core.conf
    echo "*       soft        core        unlimited" >> /etc/security/limits.d/core.conf
	
    LANG=C grep "DefaultLimitCORE" /etc/systemd/system.conf 2>&1>/dev/null && \
    sed -i "s/.*\(DefaultLimitCORE\).*/\1=infinity/g" /etc/systemd/system.conf || \
    echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
    echo "DefaultLimitCORE=infinity"
	
    LANG=C grep "DefaultLimitNOFILE" /etc/systemd/system.conf 2>&1>/dev/null && \
    sed -i "s/.*\(DefaultLimitNOFILE\).*/\1=102400/g"  /etc/systemd/system.conf || \
    echo "DefaultLimitNOFILE=102400" >> /etc/systemd/system.conf
    echo "DefaultLimitNOFILE=102400"

    systemctl daemon-reload
    systemctl daemon-reexec
    sysctl -p /etc/sysctl.d/core.conf

    action "coredump configure" /bin/true
}

#set history
function history_set() {
    file_cfg='/etc/bashrc'
    prompt_command_format='if [[ $(whoami) == "root" ]];then { date "+%Y-%m-%d %T ##### $(who am i |awk "{print \$1\" \"\$2\" \"\$5}") #### $(pwd) #### $(history 1 | { read x cmd; echo "$cmd"; })"; } >> /root/eGW/Logs/history/$(date +"%Y%m%d").log 2>/dev/null;fi'
    sed -i "/.*\(export PROMPT_COMMAND=\).*/d" $file_cfg
    echo "export PROMPT_COMMAND='$prompt_command_format'" >> $file_cfg

    #source $file_cfg

    action "history configure" /bin/true
}

#set WCG_version
#function WCG_ver_set() {
#    version="WCG-1.6.1-test"
#    mkdir -p /root/eGW/.version/versions
#    #echo lccmd:$(md5sum /usr/sbin/lccmd |awk '{print $1}') > /root/eGW/.version/versions/${version}.ver
#    echo ltegwd:$(md5sum /root/eGW/ltegwd |awk '{print $1}') > /root/eGW/.version/versions/${version}.ver
#    echo gtp-relay.ko:$(md5sum /root/eGW/gtp-relay.ko |awk '{print $1}') >> /root/eGW/.version/versions/${version}.ver
#
#    action "version configure" /bin/true
#}

#set journal
function journal_set() {
    [ ! -d "/var/log/journal" ] && mkdir -p /var/log/journal
    journalctl --vacuum-size=2G
    journalctl --vacuum-time=1years
    action "journal configure" /bin/true
}

#function config_lnk_set() {
#    ln -snf /etc/keepalived/keepalived.conf /root/eGW/keepalived.conf
#    ln -snf /etc/nginx/nginx.conf /root/eGW/nginx.conf
#}

function mkdir_history() {
    mkdir -p /root/eGW/Logs/history
}

function post_WCG_ins() {
    echo "**Run the shell after WCG install..."
    systemctl stop monitor
    #WCG_addx
    WCG_reg
    #nginx_cfg
    #redis_cfg
    #keepalived_cfg
    system_env_set
    sysctl_set
    coredump_set
    history_set
    #WCG_ver_set
    journal_set
    #config_lnk_set
    mkdir_history
    #规避升级双版本问题
    #systemctl restart monitor.service
    #systemctl restart om.service
}

post_WCG_ins

#****************************************************************************************#
%preun
#Description: This script is used to set system environment before remove WCG.
#****************************************************************************************#
#!/bin/bash

source /etc/init.d/functions

rpm_type=$1
DIR=/root/eGW

function history_unset() {
    file_cfg='/etc/bashrc'
    sed -i "/HISTORY_FILE=/d" $file_cfg
    sed -i "/export PROMPT_COMMAND=/d" $file_cfg
    source $file_cfg

    action "history unset" /bin/true
}

function WCG_stop() {
    systemctl stop monitor.service 
    tpid=$(pidof ltegwd)
    [ $tpid ] && kill -9 $tpid
    tpid=$(pidof startAll.sh)
    [ $tpid ] && kill -9 $tpid
    tpid=$(pidof vtysh)
    [ $tpid ] && kill -9 $tpid
    tpid=$(pidof egw_manage)
    [ $tpid ] && kill -9 $tpid
    tpid=$(pidof egw_report)
    [ $tpid ] && kill -9 $tpid
    tpid=$(pidof egw_manage_logger)
    [ $tpid ] && kill -9 $tpid
    tpid=$(pidof egw_monitor)
    [ $tpid ] && kill -9 $tpid	
    action "systemctl stop monitor.service" /bin/true
}

function preun_WCG_rm() {
    echo "**Run the shell before WCG uninstall..."
    history_unset
    WCG_stop
}

if [[ $rpm_type == 0 ]];then
    preun_WCG_rm
fi

#******************************************************************************************#
%postun
#Description: This script is used to set system environment after remove WCG.
#******************************************************************************************#
#!/bin/bash

#source /etc/init.d/functions

#rpm_type=$1
#echo "postun start"

#function keepalived_cfg() {
#    mv -f /etc/keepalived/keepalived.conf.bak /etc/keepalived/keepalived.conf
#    echo "mv /etc/keepalived/keepalived.conf.bak /etc/keepalived/keepalived.conf"
#}

#******************************************************************************************#
#%veryfiscript
#Description:
#******************************************************************************************#


#******************************************************************************************#
#%triggerin
#Description: 
#******************************************************************************************#


#******************************************************************************************#
#%triggerun
#Description:
#******************************************************************************************#


#******************************************************************************************#
#%trggerpostun
#Description: 
#******************************************************************************************#
