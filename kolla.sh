#!/bin/bash

build () {
	docker build -t shreddedbacon/kolla-ansible -f Dockerfile.kolla .
}

genpwd () {
	docker run -v $(pwd)/kolla-ansible:/etc/kolla -it shreddedbacon/kolla-ansible cp /usr/local/share/kolla-ansible/etc_examples/kolla/passwords.yml /etc/kolla/passwords.yml
	docker run -v $(pwd)/kolla-ansible:/etc/kolla -it shreddedbacon/kolla-ansible cp /usr/local/share/kolla-ansible/etc_examples/kolla/globals.yml /etc/kolla/globals.yml
	docker run -v $(pwd)/kolla-ansible:/etc/kolla -it shreddedbacon/kolla-ansible kolla-genpwd
}

kolla_ansible () {
	docker run \
    -v $(readlink -f $SSH_AUTH_SOCK):/ssh-agent \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -v $(pwd)/kolla-ansible:/etc/kolla \
    -it shreddedbacon/kolla-ansible kolla-ansible -i multinode --extra-vars=@overrides.yml $1
}

if [ "$1" == "genpwd" ]
then
	genpwd
elif [ "$1" == "build" ]
then
	build
else
	kolla_ansible $1
fi