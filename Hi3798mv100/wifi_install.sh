#!/bin/sh

MODULE_PATH="/lib/modules/$(uname -r)"

prepare() {
    type modprobe >/dev/null
    if [ $? -ne 0 ]; then
        ping -c 2 -w 2 114.114.114.114 > /dev/null
        if [ $? -ne 0 ];then
            echo "网络不联通，请检查网络后重试."
            exit 1
        fi
        apt update && apt install -y kmod
    fi
    
    modules_path="/lib/modules/$(uname -r)"
    mkdir -p ${MODULE_PATH}
    touch ${MODULE_PATH}/modules.builtin
    touch ${MODULE_PATH}/modules.order
    
    ln -sf /dev/null /etc/udev/rules.d/80-net-setup-link.rules
}

install() {
    if [ -n "$PACKAGE_FILE" ]; then
        prepare
        
        if [ ! -f "$PACKAGE_FILE" ]; then
            echo "输入的 "$PACKAGE_FILE" 不存在，请确认文件路径"
            exit 1
        fi
        
        file_info=$(file $PACKAGE_FILE)
        file_info_without_name=$(echo ${file_info#*: })
        file_type=$(echo $file_info_without_name | cut -d "," -f 1)
        if [ "$file_type" != "gzip compressed data" ]; then
            echo "输入的文件 "$PACKAGE_FILE" 无法解压，请输入正确文件"
            exit 1
        fi
        
        package_files=$(tar xvzf ${PACKAGE_FILE} -C ${MODULE_PATH})
        depmod
        mkdir -p /etc/modules-load.d
        rm -f /etc/modules-load.d/wifi.conf
        touch /etc/modules-load.d/wifi.conf
        echo "$package_files" | while read -r mod_file; do 
            mod_name=$(echo ${mod_file%.ko})
            modprobe $mod_name
            echo $mod_name >> /etc/modules-load.d/wifi.conf
        done
        if [ $? -eq 0 ]; then
            echo "安装成功."
        fi
    fi
}

maskdigits () {
    a=$(echo "$1" | awk -F "." '{print $1" "$2" "$3" "$4}')
    for num in $a;
    do
    while [ $num != 0 ];do
      echo -n $(($num%2)) >> /tmp/num;
      num=$(($num/2));
    done
    done
    echo $(grep -o "1" /tmp/num | wc -l)
    rm /tmp/num
}

connection() {
    if [ -n "$WIFI_SSID" ]; then
        exist_connection=$(nmcli connection |grep $WIFI_SSID)
        if [ "$exist_connection" != "" ]; then
            nmcli connection delete "$WIFI_SSID" > /dev/null
        fi
    
        nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASS" ifname wlan0 > /dev/null
        if [ $? -eq 0 ]; then
            echo "连接wifi成功."
        else
            echo "连接失败，请确认WIFI名称和密码."
            exit 1
        fi
        
        if [ -n "$WLAN_ADDRESS" ]; then
            address=$WLAN_ADDRESS
            netmask=${WLAN_NETMASK:="255.255.255.0"}
            mask_digits=$(maskdigits $netmask)
            default_gateway=$(echo ${address%.*}).1
            gateway=${WLAN_GATEWAY:="$default_gateway"}
            connection_address=$address/$mask_digits,gateway
            
            connection_file=/etc/NetworkManager/system-connections/"${WIFI_SSID}".nmconnection
            sed -i '/\[ipv4\]/{N;N;s/.*/\[ipv4\]\ndns-search=\nmethod=manual/}'  $connection_file
            sed -ri "/^method=manual/aaddresses1=${connection_address}" $connection_file
            
            nmcli connection reload "${WIFI_SSID}" > /dev/null
            nmcli connection down "${WIFI_SSID}" > /dev/null
            nmcli connection up "${WIFI_SSID}" > /dev/null

            if [ $? -eq 0 ]; then
                echo "修改地址成功."
            else
                echo "修改失败，请手工检查$connection_file"
                exit 1
            fi

        fi
    fi
}

usage() {
    cat <<-EOF
Name:     wifi_install.sh
描述:     E酷NAS盒子自动安装wifi驱动脚本.
版本:     0.1.0 (2022.04.10)
作者:     Jimmy Xiao

使用帮助: sh wifi_install.sh -f FILE [options]
可用选项:
    -f, --file
                驱动文件包 例如 rtl8188ftv.tar.gz
    -s, --ssid
                wifi名称
    -p, --password
                wifi密码
    -d, --address
                可选，固定ip地址 如 192.168.1.100
    -g, --gateway
                可选，网关 一般为 网段的第一个IP 如 192.168.1.1
    -m, --netmask
                可选，掩码 一般为 255.255.255.0
    -h, --help
                本帮助说明
EOF
    exit $1
}

main() {
    if [ -z "$1" ]; then
        usage 1
    fi
    while [ $# -gt 0 ]; do
        if [ -z "$2" ]; then
            usage 1
        else
            case "$1" in
                --help | -h)
                    usage 0
                    ;;
                --file | -f)
                    export PACKAGE_FILE=$2
                    shift
                    ;;
                --ssid | -s)
                    export WIFI_SSID=$2
                    shift
                    ;;
                --password | -p)
                    export WIFI_PASS=$2
                    shift
                    ;;
                --address | -d)
                    export WLAN_ADDRESS=$2
                    shift
                    ;;
                --netmask | -m)
                    export WLAN_NETMASK=$2
                    shift
                    ;;
                --gateway | -g)
                    export WLAN_GATEWAY=$2
                    shift
                    ;;
                *)
                    usage 1
                    ;;
            esac
        fi
        shift 1
    done
    
    install
    connection
    
}

main "$@"
