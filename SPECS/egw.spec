#制作WCG版本的spec文件

Name:       WCG
Version:    2.1.0
Release:    1%{?dist}
Summary:    WCG rpm package

License:    GPL
Packager:   dongfeng
#URL:            
Source0:    %{name}-%{version}.tar.gz
#patch0:
#BuildRequires:  
AutoReqProv: no
Requires:   nginx,redis,hiredis,fcgi,spawn-fcgi,gsoap,curl,lksctp-tools,vconfig,xinetd,tftp,tftp-server,keepalived,net-tools,ethtool     

%description
The rpm package for WCG install!


%prep
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/eGW/{redis,nginx,keepalived}
#mkdir -p $RPM_BUILD_ROOT/usr/bin
mkdir -p $RPM_BUILD_ROOT/usr/lib/eGW
#mkdir -p $RPM_BUILD_ROOT/var/log/eGW
mkdir -p $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -arf . $RPM_BUILD_ROOT/usr/lib/eGW
#cp -rf vtysh $RPM_BUILD_ROOT/usr/bin
cp -rf monitor.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf OMC/om.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf redis/redis_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf nginx/nginx_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf keepalived/keepalived_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf eGWLogCfg.conf $RPM_BUILD_ROOT/etc/eGW
cp -rf gotty.conf $RPM_BUILD_ROOT/etc/eGW
cp -rf ha.conf $RPM_BUILD_ROOT/etc/eGW
cp -rf ltegwd.xml $RPM_BUILD_ROOT/etc/eGW
cp -rf networkcfg.conf $RPM_BUILD_ROOT/etc/eGW
cp -rf vtyshLogCfg.conf $RPM_BUILD_ROOT/etc/eGW
cp -rf OMC/kpimain.conf $RPM_BUILD_ROOT/etc/eGW
cp -rf OMC/eGW_Cfg_Info.xml $RPM_BUILD_ROOT/etc/eGW
cp -rf OMC/eGW_Monitor_Cfg_Info.xml $RPM_BUILD_ROOT/etc/eGW
cp -rf TR069/eGW_Alarm_Info.xml $RPM_BUILD_ROOT/etc/eGW
cp -rf TR069/eGW_TrPath_Info.xml $RPM_BUILD_ROOT/etc/eGW
cp -rf TR069/eGW_OMCCfg_Info.xml $RPM_BUILD_ROOT/etc/eGW
cp -rf redis/redis_wcg.conf $RPM_BUILD_ROOT/etc/eGW/redis
cp -rf redis/redis_wcg-shutdown $RPM_BUILD_ROOT/etc/eGW/redis
cp -rf nginx/nginx_wcg.conf $RPM_BUILD_ROOT/etc/eGW/nginx
cp -rf keepalived/keepalived_wcg.conf $RPM_BUILD_ROOT/etc/eGW/keepalived

%clean
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR
ls | grep -v git.init | xargs rm -rf

%files
%defattr(-,root,root,-)
%doc
%config(noreplace) /usr/lib/eGW/lo.bin
%config(noreplace) /usr/lib/eGW/ls.bin
%config(noreplace) /etc/eGW
/etc/eGW
/usr/lib/eGW
/usr/lib/systemd/system/*
%exclude /usr/lib/eGW/monitor.service
%exclude /usr/lib/eGW/OMC/om.service
%exclude /usr/lib/eGW/redis/redis_wcg.service
%exclude /usr/lib/eGW/nginx/nginx_wcg.service
%exclude /usr/lib/eGW/keepalived/keepalived_wcg.service
%exclude /usr/lib/eGW/eGWLogCfg.conf
%exclude /usr/lib/eGW/gotty.conf
%exclude /usr/lib/eGW/ha.conf
%exclude /usr/lib/eGW/ltegwd.xml
%exclude /usr/lib/eGW/networkcfg.conf
%exclude /usr/lib/eGW/vtyshLogCfg.conf
%exclude /usr/lib/eGW/OMC/kpimain.conf
%exclude /usr/lib/eGW/OMC/eGW_Cfg_Info.xml
%exclude /usr/lib/eGW/OMC/eGW_Monitor_Cfg_Info.xml
%exclude /usr/lib/eGW/TR069/eGW_Alarm_Info.xml
%exclude /usr/lib/eGW/TR069/eGW_TrPath_Info.xml
%exclude /usr/lib/eGW/TR069/eGW_OMCCfg_Info.xml
%exclude /usr/lib/eGW/redis
%exclude /usr/lib/eGW/nginx
%exclude /usr/lib/eGW/keepalived
%exclude /usr/lib/eGW/initWCGOS.sh
%exclude /usr/lib/eGW/Config.sh/crypt.sh
%exclude /usr/lib/eGW/Config.sh/watchdog_crypt.sh
#%ghost
#%verify[not]
#%docdir
#%dir

%changelog
* Thu Feb 08 2018 workerwork <workerwork@qq.com> 本次版本0.0.1-1
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
DIR=/usr/lib/eGW
#[[ -d /root/eGW  ]] && rm -rf /root/eGW
#ln -sf /home/wcg/eGW /root/eGW
ln -sf /usr/lib/eGW/vtysh /usr/bin/vtysh

#register WCG and enable service
function WCG_reg() {
    systemctl daemon-reload
    systemctl enable monitor.service
    (($? == 0)) && action "systemctl enable monitor.service" /bin/true || \
    action "systemctl enable monitor.service" /bin/false
    systemctl enable om.service
    systemctl start om.service
    (($? == 0)) && action "systemctl enable/start om.service" /bin/true || \
    action "systemctl enable/start om.service" /bin/false
}

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
    core_path="/var/log/eGW/coredump"
    [ ! -d "$core_path" ] && mkdir -p $core_path && chmod 0773 $core_path
    [ -d "/root/coredump" ] && rm -rf /root/coredump
    #[ -d "/home/wcg/coredump" ] && rm -rf /home/wcg/coredump
    #ln -sf /home/wcg/coredump /root/coredump

    echo "kernel.core_pattern = $core_path/core-%e-sig%s-user%u-group%g-pid%p-time%t" > /etc/sysctl.d/core.conf
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
    prompt_command_format='if [[ $(whoami) == "root" ]];then { date "+%Y-%m-%d %T ##### $(who am i |awk "{print \$1\" \"\$2\" \"\$5}") #### $(pwd) #### $(history 1 | { read x cmd; echo "$cmd"; })"; } >> /var/log/eGW/history/$(date +"%Y%m%d").log 2>/dev/null;fi'
    sed -i "/.*\(export PROMPT_COMMAND=\).*/d" $file_cfg
    echo "export PROMPT_COMMAND='$prompt_command_format'" >> $file_cfg

    #source $file_cfg

    action "history configure" /bin/true
}

#set journal
function journal_set() {
    [ ! -d "/var/log/journal" ] && mkdir -p /var/log/journal
    journalctl --vacuum-size=2G
    journalctl --vacuum-time=1years
    action "journal configure" /bin/true
}

function post_WCG_ins() {
    echo "**Run the shell after WCG install..."
    #规避多keepalived实例问题
    systemctl mask keepalived.service
    #规避tr069升级双版本问题
    #systemctl stop monitor
    WCG_reg
    system_env_set
    sysctl_set
    coredump_set
    history_set
    journal_set
    #规避OM升级双版本问题
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
DIR=/usr/lib/eGW

function history_unset() {
    file_cfg='/etc/bashrc'
    sed -i "/HISTORY_FILE=/d" $file_cfg
    sed -i "/export PROMPT_COMMAND=/d" $file_cfg
    source $file_cfg

    action "history unset" /bin/true
}

function WCG_stop() {
    systemctl stop monitor.service 
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
