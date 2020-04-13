#!/bin/bash

# M1 Instances
openstack flavor delete 01
openstack flavor create m1.nano --id 01 --ram 256 --disk 15 --vcpus 1
openstack flavor delete 02
openstack flavor create m1.tiny --id 02 --ram 512 --disk 15 --vcpus 1
openstack flavor delete 03
openstack flavor create m1.micro --id 03 --ram 1024 --disk 15 --vcpus 1
openstack flavor delete 04
openstack flavor create m1.small --id 04 --ram 2048 --disk 15 --vcpus 1
openstack flavor delete 05
openstack flavor create m1.medium --id 05 --ram 4096 --disk 15 --vcpus 2
openstack flavor delete 06
openstack flavor create m1.large --id 06 --ram 6144 --disk 15 --vcpus 2
openstack flavor delete 07
openstack flavor create m1.xlarge --id 07 --ram 8192 --disk 15 --vcpus 6
# M2 Instances
openstack flavor delete 08
openstack flavor create m2.nano --id 08 --ram 256 --disk 15 --vcpus 2
openstack flavor delete 09
openstack flavor create m2.tiny --id 09 --ram 512 --disk 15 --vcpus 2
openstack flavor delete 10
openstack flavor create m2.micro --id 10 --ram 1024 --disk 15 --vcpus 2
openstack flavor delete 11
openstack flavor create m2.small --id 11 --ram 2048 --disk 15 --vcpus 2
# Octavia
openstack flavor delete octavia
openstack flavor create --id octavia --disk 20 --private --ram 1024 --vcpus 2 octavia

