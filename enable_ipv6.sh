#!/bin/sh

enable_ipv6() {
	echo "net.ipv6.conf.default.disable_ipv6=0" >> /etc/sysctl.conf
	echo "net.ipv6.conf.all.disable_ipv6=0" >> /etc/sysctl.conf
	# rm -rf /etc/netplan/01-netcfg.yaml
	echo ADD
	read ADD
	echo GW
	read GW
	cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
    version: 2
    renderer: networkd
    ethernets:
        ens3:
            dhcp4: yes
            dhcp6: no
            addresses:
                - $ADD::2/64
            gateway6: $GW::1
            nameservers:
                addresses:
                    - 1.1.1.1
                    - 8.8.8.8
                    - 2606:4700:4700::1111
                    - 2001:4860:4860::8888
            routes:
                -   to: $GW::1
                    scope: link
EOF
	sudo netplan apply
	ping6 -c 10 google.com
}

enable_ipv6