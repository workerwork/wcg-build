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
#Requires:   nginx,redis,hiredis,fcgi,spawn-fcgi,gsoap,curl,lksctp-tools,vconfig,xinetd,tftp,tftp-server,keepalived,net-tools,ethtool,tmux      

%description
The rpm package for WCG install!


%prep
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/home/wcg/eGW
cp -rf * $RPM_BUILD_ROOT/home/wcg/eGW
cp -rf initWCGOS.sh $RPM_BUILD_ROOT/home/wcg
mkdir -p $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf monitor.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf OMC/om.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf redis/redis_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf nginx/nginx_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system
cp -rf keepalived/keepalived_wcg.service $RPM_BUILD_ROOT/usr/lib/systemd/system

%clean
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR
ls | grep -v git.init | xargs rm -rf

%files
%defattr(-,root,root,-)
%doc
%config(noreplace) /home/wcg/eGW/networkcfg.conf
%config(noreplace) /home/wcg/eGW/ha.conf
%config(noreplace) /home/wcg/eGW/eGWLogCfg.txt
%config(noreplace) /home/wcg/eGW/OMC/eGW_Cfg_Info.xml
%config(noreplace) /home/wcg/eGW/vtyshLogCfg.txt
%config(noreplace) /home/wcg/eGW/OMC/eGW_Monitor_Cfg_Info.xml
%config(noreplace) /home/wcg/eGW/ltegwd.xml
%config(noreplace) /home/wcg/eGW/gotty.conf
%config(noreplace) /home/wcg/eGW/redis/redis_wcg.conf
%config(noreplace) /home/wcg/eGW/nginx/nginx_wcg.conf
%config(noreplace) /home/wcg/eGW/keepalived/keepalived_wcg.conf
/usr/lib/systemd/system/*
/home/wcg/eGW
/home/wcg/initWCGOS.sh
%exclude /home/wcg/eGW/monitor.service
%exclude /home/wcg/eGW/OMC/om.service
%exclude /home/wcg/eGW/redis/redis_wcg.service
%exclude /home/wcg/eGW/nginx/nginx_wcg.service
%exclude /home/wcg/eGW/keepalived/keepalived_wcg.service
%exclude /home/wcg/eGW/initWCGOS.sh
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
