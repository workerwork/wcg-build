#
# Example spec file for nginx
#
Summary: high performance web server
Name: nginx
Version: 1.2.1
Release: 1.el5.ngx
License: 2-clause BSD-like license
Group: Applications/Server
Source: http://nginx.org/download/nginx-1.2.1.tar.gz
URL: http://nginx.org/
Distribution: Linux
Packager: zhumaohai <admin@www.centos.bz>
 
%description
nginx [engine x] is a HTTP and reverse proxy server, as well as
a mail proxy server
%prep
rm -rf $RPM_BUILD_DIR/nginx-1.2.1
zcat $RPM_SOURCE_DIR/nginx-1.2.1.tar.gz | tar -xvf -
%build
cd nginx-1.2.1
./configure --prefix=/usr/local/nginx
make
%install
cd nginx-1.2.1
make install
%preun
if [ -z "`ps aux | grep nginx | grep -v grep`" ];then
killall nginx >/dev/null
exit 0
fi
%files
#/usr/local/nginx
