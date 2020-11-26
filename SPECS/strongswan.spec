Name:           strongswan
Version:	5.1.3        
Release:        1%{?dist}
Summary:        ipsec server

License:        GPL
#URL:            
Source0:  	strongswan-5.1.3.tar.gz      

BuildRequires:  gcc
Requires:	gmp-devel       

%description
ipsec server

%prep
%setup -q


%build
./configure  --prefix=/usr --sysconfdir=/etc --enable-eap-identity --enable-eap-aka --enable-eap-aka-3gpp2 --enable-eap-radius --enable-eap-sim --enable-eap-sim-file
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
%make_install


%files
%defattr(-,root,root,-)
#%attr(0555,root,root)/usr/lib
#%attr(0555,root,root)/usr/bin
#%attr(0555,root,root)/usr/sbin
#%attr(0755,root,root)/usr/lib/systemd
#%attr(0755,root,root)/usr/lib/systemd/system
%doc
%config /etc/ipsec.conf
%config /etc/strongswan.conf
/etc/ipsec.d
/etc/strongswan.d
/usr/bin/pki
/usr/lib/ipsec
/usr/lib/systemd/system/strongswan.service
/usr/libexec/ipsec
/usr/sbin/ipsec
/usr/share/man
/usr/share/strongswan


#%exclude /usr/lib/debug
#%exclude /usr/src

%changelog
