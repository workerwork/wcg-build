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
#Requires:   nginx,redis,hiredis,fcgi,spawn-fcgi,gsoap,curl,lksctp-tools,vconfig,xinetd,tftp,tftp-server,keepalived,net-tools,ethtool,tmux      

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

#*****************************************************************************************#
%post
#Description: This script is used to set system environment after install WCG.
#*****************************************************************************************#

#****************************************************************************************#
%preun
#Description: This script is used to set system environment before remove WCG.
#****************************************************************************************#

#******************************************************************************************#
%postun
#Description: This script is used to set system environment after remove WCG.
#******************************************************************************************#

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
