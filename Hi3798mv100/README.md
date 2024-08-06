# Hi3798mv100 无线驱动安装

#### 检测

首先`lsusb` 命令查看是否支持无线网卡，并记下网卡型号比如 **RTL8188ETV** 

```
root@Hi3798mv100:~# lsusb
Bus 001 Device 002: ID 0bda:0179 Realtek Semiconductor Corp. RTL8188ETV Wireless LAN 802.11n Network Adapter
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
```

如果系统版本不是0403或0302那么就考虑将内核刷成0808，否则系统版本不匹配那么驱动是安装不成功的。

#### 先刷0808内核

上传到tmp目录，执行下面命令，完成后重启

```
cd /tmp
wget https://github.com/sharedhosting/HiNAS/blob/main/Hi3798mv100/hi_kernel-mv100-0808.bin
dd if=hi_kernel-mv100-0808.bin of=/dev/mmcblk0p6
reboot
```

#### 使用脚本安装驱动

下载脚本并给权限

```
cd /tmp
wget https://github.com/sharedhosting/HiNAS/blob/main/Hi3798mv100/wifi_install.sh
chmod a+x wifi_install.sh
```

**3.使用脚本进行安装**
脚本使用方法，在命令行输入**sh wifi_install.sh -f 驱动包 [参数1] [参数1] ...**
我的网卡型号是：RTL8188ETV 那么就命令就是：

```
sh wifi_install.sh -f rtl8188etv-0808.tar.gz
```

#### Wifi使用

修改网络配置文件：
`nano /etc/network/interfaces.d/eth0`

将 auto eth0 一行内容注释掉或整行删掉，另外再加一行内容：**allow-hotplug eth0**
修改后文件内容如下：

```
##auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
```


