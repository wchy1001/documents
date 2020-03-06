#!/bin/bash
#this script used for bond nic and create vif
set -e
mode=$1;
eth1=$2;
eth2=$3
bondname=$4
count=$#
set_ip="${@: -1}"

function echo_col()
{
###输出带颜色
  echo -e "\033[32m "$1" \033[0m"
}

function usage()
{
 echo -e "\033[32m "usage:bond.sh mode interface1 interface2 bondname bondif bond.if ...setip" \033[0m"
 echo -e "\033[32m "if we set the last parameter with setip,we will enter interactive model to set ip" \033[0m"
 echo -e "\033[35m "eg: sh bond.sh 4 em1 em2 bond0 bond0.10 bond0.20 setip" \033[0m"
 exit;
}

function is_number()
{
if [ "$1" -gt 0 ] 2>/dev/null;
then
wait;
else
  usage
fi
}

function if_exist()
{
if [ ! -d /sys/class/net/$1 ];
then
echo_col "$1 not exist";
usage
fi
}

function set_interface()
{
ifdown $1 >/dev/null 2>&1
mv /etc/sysconfig/network-scripts/ifcfg-"$1" /etc/sysconfig/network-scripts/ifcfg-"$1".bak || echo_col "skip"
cat << EOF >/etc/sysconfig/network-scripts/ifcfg-$1
DEVICE="$1"
ONBOOT="yes"
BOOTPROTO=none
NM_CONTROLLED="no"
TYPE="Ethernet"
MASTER=$2
SLAVE=yes
EOF
}

function create_bond()
{
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-$2
DEVICE=$2
BOOTPROTO="none"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE=bond
BONDING_OPTS="mode=$1 miimon=100 xmit_hash_policy=layer3+4"
EOF
}

function set_ip(){
read -p "interface name:eg(bond1): " interface
read -p "ipaddress: " ipaddr
read -p "netmask: " netmask
read -p "gateway: " gateway
cat <<EOF >>/etc/sysconfig/network-scripts/ifcfg-$interface
IPADDR=$ipaddr
NETMASK=$netmask
EOF
if  [  -n "$gateway" ];then
cat <<EOF >>/etc/sysconfig/network-scripts/ifcfg-$interface
GATEWAY=$gateway
EOF
fi
}

function set_vif()
{
vlan=`echo $1 | cut -d "." -f2`
is_number "$vlan"
if [[ $vlan < 1 || $vlan > 4095 ]];
then
usage
fi
name=$(echo $1 | cut -d "." -f1)
if [[ $name != $bondname ]] ;then
echo_col "bondname is error"
usage;
fi
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-$1
DEVICE=$1
BOOTPROTO="static"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE=bond
VLAN=yes
EOF
}
########
if [[ $# < 3 ]];
then
usage
fi

is_number "$mode"
if [[ $mode > 6 || $mode < 0 ]];
then
usage
fi
if_exist "$eth1"
if_exist "$eth2"
###

###
set_interface "$eth1" "$bondname"
set_interface "$eth2" "$bondname"
create_bond "$mode" "$bondname"

if [ "$set_ip" = "setip" ];then
count=$(( $count - 1 ))
###
if [[ $count > 4 ]];
then
for i in `seq 5 "$count"`;
do
vif=$(echo $@ | cut -d ' ' -f $i)
set_vif $vif
done
fi
###
set_ip
echo_col "we have configured the $vif ip address"
else
###
if [[ $count > 4 ]];
then
for i in `seq 5 "$count"`;
do
vif=$(echo $@ | cut -d ' ' -f $i)
set_vif $vif
echo_col "please configure the $vif ip address manual"
done
fi
###
fi


ifup $eth1
ifup $eth2
systemctl restart network || echo_col "please restart the network service manual"
