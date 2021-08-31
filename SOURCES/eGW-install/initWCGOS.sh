#!/bin/bash -

systemctl disable NetworkManager.service
#systemctl disable firewalld.service
systemctl mask keepalived.service
systemctl enable om.service
systemctl enable monitor.service

mkdir -p /var/opt/lc
mkdir -p /var/opt/mo


#sed -i "s/SELINUX=enforcing/SELINUX=disabled/g"  /etc/selinux/config

sed -i "s/#Port.*/Port 50683/g" /etc/ssh/sshd_config
sed -i 's/#\(PermitRootLogin \).*/\1no/g' /etc/ssh/sshd_config

grep "export TMOUT" /etc/profile 2>&1>/dev/null || echo "export TMOUT=300" >> /etc/profile
sed -i 's/\(.*pam_pwquality.so \).*/\1retry=3 ucredit=-1 dcredit=-1 ocredit=-1/g' /etc/pam.d/system-auth
sed -i '/required/s@#auth\(.*\)@auth\1@g' /etc/pam.d/su
sed -i 's@\(^PASS_MAX_DAYS\).*@\1   90@g' /etc/login.defs
sed -i 's@\(^PASS_MIN_LEN\).*@\1    8@g' /etc/login.defs
useradd wcg && echo wcg:WCG@baicells |chpasswd && usermod -g wcg -G wheel,wcg wcg

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
echo "net.ipv4.neigh.default.gc_thresh1 = 25000" >> /etc/sysctl.conf
echo "net.ipv4.neigh.default.gc_thresh2 = 30000" >> /etc/sysctl.conf
echo "net.ipv4.neigh.default.gc_thresh3 = 40000" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.arp_ignore = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.arp_announce = 2" >> /etc/sysctl.conf
if_tmp=$(ifconfig -a | awk -F ':' '/flag/{if($1!="lo"&&$1!~/virbr/&&$1!~/docker/){print $1}}'| sort -u)
for i in $if_tmp
do
    echo "net.ipv4.conf.${i}.rp_filter = 0" >> /etc/sysctl.conf
    echo "net.ipv4.conf.${i}.arp_ignore = 1" >> /etc/sysctl.conf
    echo "net.ipv4.conf.${i}.arp_announce = 2" >> /etc/sysctl.conf
done
echo "kernel.msgmax = 8192" >> /etc/sysctl.conf
echo "kernel.msgmni = 32768" >> /etc/sysctl.conf
echo "kernel.msgmnb = 4203520" >> /etc/sysctl.conf
mkdir -p /var/log/eGW/coredump && chmod 0773 /var/log/eGW/coredump
echo "kernel.core_pattern = /var/log/eGW/coredump/core-%e-sig%s-user%u-group%g-pid%p-time%t" > /etc/sysctl.d/core.conf
echo "kernel.core_uses_pid = 1" >> /etc/sysctl.d/core.conf
echo "fs.suid_dumpable = 2" >> /etc/sysctl.d/core.conf
echo "*       hard        core        unlimited" > /etc/security/limits.d/core.conf
echo "*       soft        core        unlimited" >> /etc/security/limits.d/core.conf
echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=102400" >> /etc/systemd/system.conf
mkdir -p /var/log/eGW/history
file_cfg='/etc/bashrc'
prompt_command_format='if [[ $(whoami) == "root" ]];then { date "+%Y-%m-%d %T ##### $(who am i |awk "{print \$1\" \"\$2\" \"\$5}") #### $(pwd) #### $(history 1 | { read x cmd; echo "$cmd"; })"; } >> /var/log/eGW/history/$(date +"%Y%m%d").log 2> /dev/null;fi'
sed -i "/.*\(export PROMPT_COMMAND=\).*/d" $file_cfg
echo "export PROMPT_COMMAND='$prompt_command_format'" >> $file_cfg
mkdir -p /var/log/journal
journalctl --vacuum-size=2G
journalctl --vacuum-time=1years
