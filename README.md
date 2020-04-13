
# OpenStack Lab

This isn't really a guide, but more a reference to my own OpenStack lab and how it is set up using Kolla-ansible

   * [OpenStack Lab](#openstack-lab)
      * [Hardware Considerations](#hardware-considerations)
      * [Diagram](#diagram)
      * [Routing / IP Ranges / VLANs](#routing--ip-ranges--vlans)
            * [IP Ranges / VLANs](#ip-ranges--vlans)
            * [Routing / Rules](#routing--rules)
         * [DNS](#dns)
         * [Switch configuration](#switch-configuration)
         * [Node Interfaces](#node-interfaces)
         * [VLANs](#vlans)
         * [Firewall Rules](#firewall-rules)
      * [Initial Setup](#initial-setup)
         * [Prepare Nodes](#prepare-nodes)
            * [Node Networking](#node-networking)
            * [SSH Access](#ssh-access)
      * [OpenStack Configuration](#openstack-configuration)
         * [Cinder Storage](#cinder-storage)
      * [Deploy](#deploy)
         * [Install kolla-ansible](#install-kolla-ansible)
         * [Configure](#configure)
            * [Generate passwords](#generate-passwords)
            * [Inventory](#inventory)
            * [Overrides](#overrides)
         * [Bootstrap Servers](#bootstrap-servers)
         * [Pre-checks](#pre-checks)
         * [Deploy](#deploy-1)
      * [Post Deploy Tasks](#post-deploy-tasks)
         * [OpenStack client rc.sh](#openstack-client-rcsh)
         * [External Network Providers](#external-network-providers)
            * [VLAN 101 - Floating IP Range](#vlan-101---floating-ip-range)
            * [VLAN 102 - Floating IP Range](#vlan-102---floating-ip-range)
            * [VLAN 103 - Floating IP Range](#vlan-103---floating-ip-range)
            * [VLAN 104 - Amphora Network](#vlan-104---amphora-network)
         * [Image Flavors](#image-flavors)
            * [M1 Instance Flavors](#m1-instance-flavors)
            * [M2 Instance Flavors](#m2-instance-flavors)
            * [Octavia Flavor](#octavia-flavor)
         * [Octavia](#octavia)
      * [Finish](#finish)
      * [References](#references)

## Hardware Considerations
My lab consists of the following for the purpose of this reference:

* 3x API/control nodes
	* Intel Celeron CPU J1900
	* Dual Ethernet (my network node has Quad Ethernet, but not required)
	* 8GB RAM
	* CentOS 7
* 3x Compute nodes
	* Intel Core i7-5500U CPU
	* Dual Ethernet
	* 16GB RAM
	* CentOS 7
* 1x Dell 6248 Switch
* 1x Synology NAS

## Diagram
[Lucid Chart](https://www.lucidchart.com/documents/view/93c11631-333f-4627-b082-18d8c5c4e657)

## Routing / IP Ranges / VLANs
Routing should be set up with some initial networks, feel free to change your networks to be whatever you want.
#### IP Ranges / VLANs
* `10.10.10.0/24` - Primary network for all non tenant/external networking traffic
	* This will use `VLAN 100`
	* `10.10.10.11-20` is used for any control nodes
	* `10.10.10.21-30` is used for any network nodes
	* `10.10.10.31-40` is used for any storage nodes
	* `10.10.10.101-199` is used for any compute nodes
	* `10.10.10.200-249` is used for any other devices in the network
	* `10.10.10.250` is used for the VIP for keystone/horizon
* `10.10.11.0/24` - External network 1 - Used for floating IP addresses
	* This will use `VLAN 101`
* `10.10.12.0/24` - External network 2 - Used for floating IP addresses
	* This will use `VLAN 102`
* `10.10.13.0/24` - External network 3 - Used for floating IP addresses
	* This will use `VLAN 103`
* `10.10.14.0/24` - Amphora network
	* This will use `VLAN 104`

#### Routing / Rules
You need to make sure that `10.10.10.0/24` can access `10.10.14.0/24` as this is required for Octavia to be able to provision/deprovision amphora instances

### DNS
Each node must be resolvable by its DNS name, so you can either run your own DNS server like this [https://hub.docker.com/r/doko89/technitium](https://hub.docker.com/r/doko89/technitium) or however you want to handle your DNS (if your router can do it, great)

### Switch configuration
See [Dell PowerConnect 6248](switch-config/dell-6248.md)

### Node Interfaces
* `bond0` is the network used for everything except for external network and VLAN tenant traffic
* `bond1` is used for external network and VLAN tenant traffic

### VLANs
Configurable in `kolla-ansible/config/neutron/ml2_conf.ini`
* `100` - This is the VLAN all bond0 interfaces run in
* `101-104` - These VLANs are used for external networks, these are networks that Floating IP addresses and Amphora images will use
* `105-900` - Tenant VLANs 

### Firewall Rules


## Initial Setup
### Prepare Nodes
First step is to prepare all the nodes by installing CentOS 7 as the base OS, just do a minimal installation. Don't install anything else, we will run a script over each node that will set them up for use by our eventual run of `kolla-ansible`
#### Node Networking
First step is to configure the network interfaces for each node.

You should update the scripts referenced below with any hostname changes you make to the nodes

Review the scripts in `node-scripts/**/setup.sh` for each node, configure the IP address section to suit your networking ranges. Adjust accordingly and then copy and run them on each of your nodes. Best to do this via keyboard/mouse/monitor or iDRAC/iLO(if your nodes have it)

By default, the configuration is as follows for each node
* `control01 - 10.10.10.11`
* `network01 - 10.10.10.21`
* `storage01 - 10.10.10.31`
* `compute01 - 10.10.10.101`
* `compute02 - 10.10.10.102`
* `compute03 - 10.10.10.103`

#### SSH Access
Make sure that wherever you will run `kolla-ansible` can SSH to all the nodes.

## OpenStack Configuration
### Cinder Storage
I set up an NFS share on my NAS to provide the cinder backend, feel free to do whatever you want though and not use NFS.
If you do create the NFS share, make sure it is accessible by your nodes.
> Note: Having an IP in the same subnet and on the same physical switch would be ideal.

Create 2 shares, one for volumes, one for volume backups
```
10.10.10.200:/volume1/openstack
10.10.10.200:/volume1/openstack-backups
```
These need to be set in 
* `kolla-ansible/config/nfs_shares`
* `kolla-ansible/globals.yml` - `cinder_backup_share: `

## Deploy
### Install kolla-ansible
I put together a quick docker image that contains `kolla-ansible`  and `ansible` in the one image.
There is a wrapper for this called `kolla.sh` that you can use, it just passes everything through to kolla-ansible except for `build` and `genpwd`

You can run `./kolla.sh build` to build the docker-image if you want, otherwise follow the guide to get setup with kolla-ansible.

### Configure
#### Generate passwords
Then the first step is to get the latest `globals.yml` and `passwords.yml` and populate the passwords with auto generated ones. 
```
./kolla.sh genpwd
```
This will populate `kolla-ansible/passwords.yml` locally, keep this somewhere safe.
> NOTE: You only need to run this initially to generate passwords.

#### Inventory
The inventory file is located in `kolla-ansible/multinode` adjust this to suit however you want to deploy the different servers across your nodes. 

You should update this with any hostname changes you make to the nodes

#### Overrides
`kolla-ansible/overrides.yml` is where we will configure any overrides for the configuration of our openstack.
Take options from the `kolla-ansible/globals.yml` and add them here to override.

You can also add property config additions/overrides of particular services directly in `kolla-ansible/config/<service>`

### Bootstrap Servers
First thing we need to do is bootstrap the servers, this will install everything needed to run kolla-ansible and all the images it uses.
```
./kolla.sh bootstrap-servers
```
### Pre-checks
Once the bootstrap is done, run pre-checks
```
./kolla.sh prechecks
```
### Deploy
Once the pre-checks are done, you can deploy the images (this can take quite some time)
```
./kolla.sh deploy
```

## Post Deploy Tasks
### OpenStack client rc.sh
Once the deployment is done, you can generate a copy of the `admin-openrc.sh` file running the following
```
./kolla.sh post-deploy
```
This will create `kolla-ansible/admin-openrc.sh` that you can source to interact with openstack using the CLI

### External Network Providers
Once deployed, you should create all the external network providers `./openstack-scripts/provider-networks.sh`

#### VLAN 101 - Floating IP Range
```
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
```
#### VLAN 102 - Floating IP Range
```
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
```
#### VLAN 103 - Floating IP Range
```
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
```
#### VLAN 104 - Amphora Network
```
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
```

### Image Flavors
You'll need to set up some image flavors for any instances, you can use ones I've created `./openstack-scripts/flavors.sh`
#### M1 Instance Flavors
```
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
```
#### M2 Instance Flavors
```
openstack flavor delete 08
openstack flavor create m2.nano --id 08 --ram 256 --disk 15 --vcpus 2
openstack flavor delete 09
openstack flavor create m2.tiny --id 09 --ram 512 --disk 15 --vcpus 2
openstack flavor delete 10
openstack flavor create m2.micro --id 10 --ram 1024 --disk 15 --vcpus 2
openstack flavor delete 11
openstack flavor create m2.small --id 11 --ram 2048 --disk 15 --vcpus 2
```
#### Octavia Flavor
```
openstack flavor delete octavia
openstack flavor create --id octavia --disk 20 --private --ram 1024 --vcpus 2 octavia
```

### Octavia
This guide has a good runthrough on setting up octavia after initially deploying openstack
[http://www.panticz.de/openstack/octavia](http://www.panticz.de/openstack/octavia)

You can deploy just octavia again once configuration options are changed using
```
./kolla deploy --tags octavia
```

## Finish
You're done, you should be able to access horizon now by visiting [http://10.10.10.250/](http://10.10.10.250/) (or whatever IP you configured as your `kolla_internal_vip_address` in `kolla-ansible/overrides.yml` file.

## References
The following were used to help in the initial deployment of my openstack lab

*[Kolla-ansible quickstart](https://docs.openstack.org/kolla-ansible/latest/user/quickstart.html)
*[http://www.panticz.de/openstack/octavia](http://www.panticz.de/openstack/octavia)