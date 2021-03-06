#!/bin/sh

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
user=vilas
pass=vilas123
FIRST_PORT=10000
LAST_PORT=10250
ifname=ens3

random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 2000
nserver 1.1.1.1
nserver 1.0.0.1
nserver 2606:4700:4700::64
nserver 2606:4700:4700::6400
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
# setgid 65535
# setuid 65535
stacksize 6291456
flush
auth strong
users $user:CL:$pass
auth strong
allow $user
$(awk -F "/" '{print "proxy -6 -n -a -p" $4 " -i" $3 " -e"$5""}' ${WORKDATA})
flush
EOF
	systemctl restart 3proxy
}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "$user/$pass/$IP4/$port/$(gen64 $IP6)/$ifname"
    done
}

gen_iptables() {
    cat <<EOF
$(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig " $6 " inet6 add " $5 "/64"}' ${WORKDATA})
EOF
}

gen_ping () {
	cat <<EOF
$(awk -F "/" '{print $5}' ${WORKDATA})
EOF
}

systemctl restart networking
rm -rf $WORKDIR/

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir -p $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
echo $IP4
echo $IP6


gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
gen_ping >$WORKDIR/ips
split -l 130 $WORKDIR/ips $WORKDIR/ips.
gen_3proxy >/usr/local/3proxy/conf/3proxy.cfg
wget -P $WORKDIR https://github.com/chucuoi1/test_ipv6/raw/main/checka.sh
wget -P $WORKDIR https://github.com/chucuoi1/test_ipv6/raw/main/checkb.sh

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
screen -dmS checka bash $WORKDIR/checka.sh
screen -dmS checkb bash $WORKDIR/checkb.sh
EOF
chmod +x $WORKDIR/*.sh
bash /etc/rc.local
