#!/usr/bin/env bash
#########################################################################################
# crypt.sh
# version:1.0
# update:20210129
#########################################################################################

function base64_i() {
    files=$1
    for file in $files
    do
        if [ -f $file ];then
            dir=$(dirname $file)
            base=$(basename $file)
            echo $base |grep ".swp" && continue
            cat $file |base64 -i > ${dir}/${base#.*}.crypt
        fi
    done
}

function base64_d() {
    files=$1  
    for file in $files
    do
        if [ -f $file ];then
            cat $file 2>/dev/null |base64 -d > ${file%.*}
        fi
    done
}


ARGS=`getopt -o hvc:u: --long help,version,crypt:,uncrypt: -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$ARGS"
while true;do
    case "$1" in
        -c|--crypt)
            base64_i "$2"
            shift 2
            ;;
        -u|--uncrypt)
            base64_d "$2"
            shift 2
            ;;
        -v|--version)
            echo "version: 1.0"
            shift 
            ;;
        -h|--help)
            echo "usage:"
            echo "  -h  --help                    list help information"
            echo "  -v  --version                 list the released version"
            echo "  -c  --crypt [files]           crypt files"
            echo "  -u  --uncrypt [files]         uncrypt files"
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
