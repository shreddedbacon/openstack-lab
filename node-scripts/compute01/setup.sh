#!/bin/bash

## 
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/sysconfig/selinux

hostnamectl set-hostname compute01.example.local

## First step is to set up bonds, even though we only have 1 interface per bond, it just makes naming easier across all nodes
cat > /etc/sysconfig/network-scripts/ifcfg-bond0 << EOF
DEVICE=bond0
NM_CONTROLLED=no
USERCTL=no
BOOTPROTO=none
BONDING_OPTS="mode=0 miimon=100"
TYPE=Ethernet
IPADDR=10.10.10.101
NETMASK=255.255.255.0
GATEWAY=10.10.10.1
DNS1=10.10.10.1
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-bond1 << EOF
DEVICE=bond1
NM_CONTROLLED=no
USERCTL=no
BOOTPROTO=none
BONDING_OPTS="mode=0 miimon=100"
TYPE=Ethernet
EOF

## Get the interface name and UUID and populate them here, remember which one is which physically
cat > /etc/sysconfig/network-scripts/ifcfg-enp2s0 << EOF
NM_CONTROLLED=no
BOOTPROTO=none
DEVICE=enp2s0
ONBOOT=yes
USERCTL=no
MASTER=bond0
SLAVE=yes
NAME=enp2s0
UUID=c61511d9-6e93-4e44-9f19-59ba79ad53ce
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp4s0 << EOF
NM_CONTROLLED=no
BOOTPROTO=none
DEVICE=enp4s0
ONBOOT=yes
USERCTL=no
MASTER=bond1
SLAVE=yes
NAME=enp4s0
UUID=8a59a473-7689-4f66-9906-e5eb040b7016
EOF

systemctl restart network
ip a
reboot
