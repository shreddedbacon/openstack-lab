#!/bin/bash

# VLAN 101 - Floating IP Range
openstack network create --share --external \
  --provider-physical-network physnet1 \
  --provider-segment 101 \
  --provider-network-type vlan \
  extnet-vlan101
openstack subnet create --no-dhcp \
  --allocation-pool start=10.10.11.10,end=10.10.11.200 \
  --network extnet-vlan101 \
  --subnet-range 10.10.11.0/24 
  --gateway 10.10.11.1 \
  extnet-vlan101-subnet

# VLAN 102 - Floating IP Range
openstack network create --share --external \
  --provider-physical-network physnet1 \
  --provider-segment 102 \
  --provider-network-type vlan \
  extnet-vlan102
openstack subnet create --no-dhcp \
  --allocation-pool start=10.10.12.10,end=10.10.12.200 \
  --network extnet-vlan102 \
  --subnet-range 10.10.12.0/24 
  --gateway 10.10.12.1 \
  extnet-vlan102-subnet

# VLAN 103 - Floating IP Range
openstack network create --share --external \
  --provider-physical-network physnet1 \
  --provider-segment 103 \
  --provider-network-type vlan \
  extnet-vlan103
openstack subnet create --no-dhcp \
  --allocation-pool start=10.10.13.10,end=10.10.13.200 \
  --network extnet-vlan103 \
  --subnet-range 10.10.13.0/24 
  --gateway 10.10.13.1 \
  extnet-vlan103-subnet

# VLAN 104 - Amphora Network
openstack network create --share --external \
  --provider-physical-network physnet1 \
  --provider-segment 104 \
  --provider-network-type vlan \
  extnet-vlan104
openstack subnet create --no-dhcp \
  --allocation-pool start=10.10.14.10,end=10.10.14.200 \
  --network extnet-vlan104 \
  --subnet-range 10.10.14.0/24 
  --gateway 10.10.14.1 \
  extnet-vlan104-subnet
