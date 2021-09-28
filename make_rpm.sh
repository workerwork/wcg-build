#!/bin/bash -
#########################################################################################
# make_rpm.sh
# version:1.1
# update:20181031
#########################################################################################
function installsoftware() {
    rpm -qa | grep epel-release
    [[ $? == 1 ]] && yum install -y epel-release
    rpm -qa | egrep rpm-build-[0-9]+
    [[ $? == 1 ]] && yum install -y rpm-build
    rpm -qa | grep rpm-sign
    [[ $? == 1 ]] && yum install -y rpm-sign
    #rpm -qa | grep ^git
    #[[ $? == 1 ]] && yum install -y git
    rpm -qa | grep ^gnupg
    [[ $? == 1 ]] && yum install -y gnupg
    rpm -qa | grep ^expect 
    [[ $? == 1 ]] && yum install -y expect
}

function setrpmmacro() {
    [[ ! ~/.rpmmacros ]] && touch ~/.rpmmacros
    [[ $(grep "%_signature" ~/.rpmmacros) ]] && \
        sed -i "s/.*\(%_signature\).*/\1 gpg/" ~/.rpmmacros || \
        echo "%_signature gpg" >> ~/.rpmmacros
    [[ $(grep "%_gpg_path" ~/.rpmmacros) ]] && \
        sed -i "s/.*\(%_gpg_path\).*/\1 ~\/.gnupg/" ~/.rpmmacros || \
        echo "%_gpg_path ~/.gnupg" >> ~/.rpmmacros
    if [[ ! $1 ]];then
        [[ $(grep "%_gpg_name" ~/.rpmmacros) ]] && \
            sed -i "s/.*\(%_gpg_name\).*/\1 baicells <baicells@baicells.com>/" ~/.rpmmacros || \
            echo "%_gpg_name baicells <baicells@baicells.com>" >> ~/.rpmmacros
    elif [[ $1 ]];then
        [[ $(grep "%_gpg_name" ~/.rpmmacros) ]] && \
            sed -i "s/.*\(%_gpg_name\).*/\1 $1/" ~/.rpmmacros || \
            echo "%_gpg_name $1" >> ~/.rpmmacros
    fi
    [[ $(grep "%_gpgbin" ~/.rpmmacros) ]] && \
            sed -i "s@.*\(%_gpgbin\).*@\1 $(which gpg)@" ~/.rpmmacros || \
            echo "%_gpgbin $(which gpg)" >> ~/.rpmmacros
}

function makerpm_egw() {
    spec=$1
    name=$(awk '/Name:/{print $2}' $spec)
    version=$(awk '/Version:/{print $2}' $spec)
    release=$(awk '/Release/{print $2}' $spec |awk -F '%' '{print $1}')
    cd SOURCES
    cp -rf eGW-install $name-$version
    tar -zcvf $name-$version.tar.gz $name-$version
    rm -rf $name-$version
    cd ..
    rpmbuild -bb $spec \
        --define "_topdir $(pwd)" \
        --define "debug_package %{nil}" \
        --define "__os_install_post %{nil}"
        #--define "_signature gpg" \
        #--define "_gpg_path /$(whoami)/.gnupg" \
        #--define "_gpg_name baicells <baicells@baicells.com>" \
        #--define "_gpgbin $(which gpg)" \
        #--sign
    #if [[ $spec == "SPECS/egw.spec" ]];then
    #    mv -f RPMS/x86_64/$name-$version-$release*.rpm .
    #elif [[ $spec == "SPECS/egw_base.spec" ]];then
    #    mv -f RPMS/x86_64/$name-$version-$release*.rpm .
    #fi
    mv -f RPMS/x86_64/$name-$version-$release*.rpm ./BaiWCG_${version_input}.centos.x86_64.rpm
    rm -f RPMS/x86_64/*.rpm
    rm -f SOURCES/$name-$version.tar.gz
}

function setversion_egw() {
    spec=$1
    version_input=$2
    version=$(echo $version_input|awk -F. '{print $1"."$2"."$3}')
    release=$(echo $version_input|awk -F. '{print $4}')
    release=${release:-"0"}
    #echo "version=$version release=$release"
    if [[ ! $version ]];then
        sed -i "s/\(Version:\).*/\1    1.0.0/" $spec
    else
        sed -i "s/\(Version:\).*/\1    $version/" $spec
    fi
    if [[ ! $release ]];then
        sed -i "s/\(Release:\).*%/\1    1%/" $spec
    else
        sed -i "s/\(Release:\).*%/\1    $release%/" $spec
    fi

}

function setgpgkey() {
    gpg --list-key | grep "baicells <baicells@baicells.com>"
    [[ $? == 1 ]] && gpg --import gpgkey/subkey
}

function addsign() {
    #rpmname=$(find . -maxdepth 1 -name "$name-$version-$release*.rpm")
    expect << EOF
    set timeout 5
    #set rpmname [lindex $argv 0]
    spawn rpm --addsign BaiWCG_${version_input}.centos.x86_64.rpm
    expect {
        "Enter pass phrase: " { send "baicells\r" }  
        "输入密码：" { send "baicells\r" }  
    }
    expect eof;
EOF
}

function init() {
    spec=$1
    setrpmmacro
    setversion_egw $spec
    setgpgkey
}

#install software
installsoftware
#init
init SPECS/egw.spec
init SPECS/egw_base.spec
init SPECS/egw_India.spec

ARGS=`getopt -o hbv:s: --long help,base,India,version,sign: -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$ARGS"
while true;do
    case "$1" in
        -s|--sign)
            #echo "-s | --sign"
            setrpmmacro "$2"
            shift 2
            ;;
        -v|--version)
            setversion_egw SPECS/egw.spec $2
            setversion_egw SPECS/egw_base.spec $2
            setversion_egw SPECS/egw_India.spec $2
            #echo "version: $2"
            shift 2
            ;;
        -b|--base)
            spec_b=SPECS/egw_base.spec
            shift
            ;;
        --India)
            spec_i=SPECS/egw_India.spec
            shift
            ;;
        -h|--help)
            echo "-h | --help"
            shift
            ;;
        --)
            shift
            break
            ;;
        *) 
            echo "unknown:{$1}"
            exit 1
            ;;
    esac
done

if [[ $spec_b ]];then
    makerpm_egw $spec_b && addsign
fi

if [[ $spec_i ]];then
    makerpm_egw $spec_i && addsign
fi

if [[ ! $spec_b ]] && [[ ! $spec_i ]];then
    makerpm_egw SPECS/egw.spec && addsign
fi


