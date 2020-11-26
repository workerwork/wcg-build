#!/bin/bash -
#########################################################################################
# build.sh
# version:1.1
# update:20181031
#########################################################################################
DIR=/home/wcg/WCG-Daily-Build
cd $DIR/WCG-build
rpm -qa |grep epel-release
[[ $? == 1 ]] && yum install -y epel-release
rpm -qa | grep ^expect
[[ $? == 1 ]] && yum install -y expect
git reset --hard
./update.exp
mv -f ../*.tar.gz . || exit 1
tar -zxvf *.tar.gz
[[ -f ltegwd ]] && chmod +x ltegwd && mv -f ltegwd eGW-install/
[[ -f gtp-relay.ko ]] && mv -f gtp-relay.ko eGW-install/ 
[[ -f vtysh ]] && chmod +x vtysh && mv -f vtysh eGW-install/
[[ -f egwTool ]] && chmod +x egwTool && mv -f egwTool eGW-install/Tools/
[[ -f egw_om ]] && chmod +x egw_om && mv -f egw_om eGW-install/OMC/
[[ -f egw_monitor ]] && chmod +x egw_monitor && mv -f egw_monitor eGW-install/OMC/
[[ -f egw_report ]] && chmod +x egw_report && mv -f egw_report eGW-install/OMC/
[[ -f egw_manage ]] && chmod +x egw_manage && mv -f egw_manage eGW-install/OMC/
[[ -f egw_manage_logger ]] && chmod +x egw_manage_logger && mv -f egw_manage_logger eGW-install/OMC/
[[ -f kpiMain ]] && chmod +x kpiMain && mv -f kpiMain eGW-install/OMC/
[[ -f config/app.conf ]] && mv -f config eGW-install/OMC/
rm -rf *.tar.gz
./make_rpm.sh -v $(date "+%Y%m%d") -r 1
mv -f *.rpm ..
