#!/bin/sh



enable_ipv6() {
	echo "net.ipv6.conf.default.disable_ipv6=0" >> /etc/sysctl.conf
	echo "net.ipv6.conf.all.disable_ipv6=0" >> /etc/sysctl.conf
	cat >>/etc/network/interfaces <<EOF
iface ens3 inet6 static
pre-up modprobe ipv6
address $1::2/64
gateway 2604:7c00:16::1
EOF
	systemctl restart networking
}

echo ADD
ADD=$(read)
echo GW
GW=$(read)