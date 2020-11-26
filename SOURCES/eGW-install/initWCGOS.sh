#!/bin/bash -

systemctl daemon-reload
systemctl stop NetworkManager.service && systemctl disable NetworkManager.service
systemctl restart om.service && systemctl enable om.service
[[ -d /root/eGW  ]] && rm -rf /root/eGW
ln -sf /home/wcg/eGW /root/eGW
[ ! -d "/var/opc/lc"  ] && mkdir -p /var/opt/lc
[ ! -d "/var/opc/mo"  ] && mkdir -p /var/opt/mo

systemctl stop firewalld.service && systemctl disable firewalld.service
ulimit -c unlimited
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g"  /etc/selinux/config
sed -i "s/#Port.*/Port 50683/g" /etc/ssh/sshd_config
sed -i 's/#\(PermitRootLogin \).*/\1no/g' /etc/ssh/sshd_config
systemctl restart sshd.service
grep "export TMOUT" /etc/profile 2>&1>/dev/null || echo "export TMOUT=300" >> /etc/profile
sed -i 's/\(.*pam_pwquality.so \).*/\1retry=3 ucredit=-1 dcredit=-1 ocredit=-1/g' /etc/pam.d/system-auth
sed -i '/required/s@#auth\(.*\)@auth\1@g' /etc/pam.d/su
sed -i 's@\(^PASS_MAX_DAYS\).*@\1   90@g' /etc/login.defs
sed -i 's@\(^PASS_MIN_LEN\).*@\1    8@g' /etc/login.defs
useradd wcg && echo wcg:WCG@baicells |chpasswd && usermod -g wcg -G wheel,wcg wcg
[ -f /etc/issue  ] && mv /etc/issue /etc/issue.bak
[ -f /etc/issue.net  ] && mv /etc/issue.net /etc/issue.net.bak

grep "net.ipv4.ip_forward" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.ip_forward\).*/\1 = 1/g"  /etc/sysctl.conf || \
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
grep "net.ipv4.tcp_tw_reuse" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.tcp_tw_reuse\).*/\1 = 1/g" /etc/sysctl.conf || \
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
grep "net.ipv4.tcp_tw_recycle" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.tcp_tw_recycle\).*/\1 = 1/g" /etc/sysctl.conf || \
echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
grep "net.ipv4.tcp_syncookies" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.tcp_syncookies\).*/\1 = 1/g" /etc/sysctl.conf || \
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
grep "net.ipv4.tcp_fin_timeout" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.tcp_fin_timeout\).*/\1 = 30/g" /etc/sysctl.conf || \
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
grep "net.ipv4.neigh.default.gc_thresh1" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.neigh.default.gc_thresh1\).*/\1 = 25000/g"  /etc/sysctl.conf || \
echo "net.ipv4.neigh.default.gc_thresh1 = 25000" >> /etc/sysctl.conf
grep "net.ipv4.neigh.default.gc_thresh2" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.neigh.default.gc_thresh2\).*/\1 = 30000/g"  /etc/sysctl.conf || \
echo "net.ipv4.neigh.default.gc_thresh2 = 30000" >> /etc/sysctl.conf
grep "net.ipv4.neigh.default.gc_thresh3" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.neigh.default.gc_thresh3\).*/\1 = 40000/g"  /etc/sysctl.conf || \
echo "net.ipv4.neigh.default.gc_thresh3 = 40000" >> /etc/sysctl.conf
grep "net.ipv4.conf.all.rp_filter" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.conf.all.rp_filter\).*/\1 = 0/g"  /etc/sysctl.conf || \
echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.conf
grep "net.ipv4.conf.all.arp_ignore" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.conf.all.arp_ignore\).*/\1 = 1/g"  /etc/sysctl.conf || \
echo "net.ipv4.conf.all.arp_ignore = 1" >> /etc/sysctl.conf
grep "net.ipv4.conf.all.arp_announce" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(net.ipv4.conf.all.arp_announce\).*/\1 = 2/g"  /etc/sysctl.conf || \
echo "net.ipv4.conf.all.arp_announce = 2" >> /etc/sysctl.conf
if_tmp=$(ifconfig -a | awk -F ':' '/flag/{if($1!="lo"&&$1!~/virbr/&&$1!~/docker/){print $1}}'| sort -u)
for i in $if_tmp
do
    grep "net.ipv4.conf.${i}.rp_filter" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.conf.${i}.rp_filter\).*/\1 = 0/g"  /etc/sysctl.conf || \
    echo "net.ipv4.conf.${i}.rp_filter = 0" >> /etc/sysctl.conf
    grep "net.ipv4.conf.${i}.arp_ignore" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.conf.${i}.arp_ignore\).*/\1 = 1/g"  /etc/sysctl.conf || \
    echo "net.ipv4.conf.${i}.arp_ignore = 1" >> /etc/sysctl.conf
    grep "net.ipv4.conf.${i}.arp_announce" /etc/sysctl.conf 2>&1>/dev/null && \
    sed -i "s/.*\(net.ipv4.conf.${i}.arp_announce\).*/\1 = 2/g"  /etc/sysctl.conf || \
    echo "net.ipv4.conf.${i}.arp_announce = 2" >> /etc/sysctl.conf
done
grep "kernel.msgmni" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(kernel.msgmax\).*/\1 = 8192/g"  /etc/sysctl.conf || \
echo "kernel.msgmax = 8192" >> /etc/sysctl.conf
grep "kernel.msgmax" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(kernel.msgmni\).*/\1 = 32768/g"  /etc/sysctl.conf || \
echo "kernel.msgmni = 32768" >> /etc/sysctl.conf
grep "kernel.msgmnb" /etc/sysctl.conf 2>&1>/dev/null && \
sed -i "s/.*\(kernel.msgmnb\).*/\1 = 4203520/g"  /etc/sysctl.conf || \
echo "kernel.msgmnb = 4203520" >> /etc/sysctl.conf
sysctl -p
[ ! -d "/root/coredump"  ] && mkdir -p /root/coredump && chmod 0773 /root/coredump
echo "kernel.core_pattern = /root/coredump/core-%e-sig%s-user%u-group%g-pid%p-time%t" > /etc/sysctl.d/core.conf
echo "kernel.core_uses_pid = 1" >> /etc/sysctl.d/core.conf
echo "fs.suid_dumpable = 2" >> /etc/sysctl.d/core.conf
echo "*       hard        core        unlimited" > /etc/security/limits.d/core.conf
echo "*       soft        core        unlimited" >> /etc/security/limits.d/core.conf
grep "DefaultLimitCORE" /etc/systemd/system.conf 2>&1>/dev/null && \
sed -i "s/.*\(DefaultLimitCORE\).*/\1=infinity/g" /etc/systemd/system.conf || \
echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
grep "DefaultLimitNOFILE" /etc/systemd/system.conf 2>&1>/dev/null && \
sed -i "s/.*\(DefaultLimitNOFILE\).*/\1=102400/g"  /etc/systemd/system.conf || \
echo "DefaultLimitNOFILE=102400" >> /etc/systemd/system.conf
systemctl daemon-reload
systemctl daemon-reexec
sysctl -p /etc/sysctl.d/core.conf
[ ! -d /root/eGW/Logs/history ] && mkdir -p /root/eGW/Logs/history
file_cfg='/etc/bashrc'
prompt_command_format='if [[ $(who am i) == "root" ]];then { date "+%Y-%m-%d %T ##### $(who am i |awk "{print \$1\" \"\$2\" \"\$5}") #### $(pwd) #### $(history 1 | { read x cmd; echo "$cmd"; })"; } >> /root/eGW/Logs/history/$(date +"%Y%m%d").log &> /dev/null;fi'
sed -i "/.*\(export PROMPT_COMMAND=\).*/d" $file_cfg
echo "export PROMPT_COMMAND='$prompt_command_format'" >> $file_cfg
[ ! -d "/var/log/journal"  ] && mkdir -p /var/log/journal
journalctl --vacuum-size=2G
journalctl --vacuum-time=1years
