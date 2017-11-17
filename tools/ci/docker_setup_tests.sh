#!/bin/sh -xe

# This script starts docker and systemd (if el7)

# Version of CentOS/RHEL
el_version=$1

# Commands and paths
DOCKERPATH=/splints
BUILDDEPS="yum install -y git perl-SOAP-Lite"

# Debug
DEBUG=1

if [ "$DEBUG" -eq "1" ]; then
	uname -a
	date
	pwd
	ls -al
fi

# Run tests in Container
# Use `--privileged` for cgroup compatability
if [ "$el_version" -eq "6" ]; then

	sudo docker run \
		--privileged \
		-v /sys/fs/cgroup:/sys/fs/cgroup --rm=true \
		-v `pwd`:$DOCKERPATH:rw centos:centos${OS_VERSION} \
		/bin/bash -c "$BUILDDEPS; pwd; ls -al; perl -c splints/src/perl/fp/v11/splints.pl"

elif [ "$el_version" -eq "7" ]; then

	docker run \
		--privileged -d -ti -e "container=docker"  \
		-v /sys/fs/cgroup:/sys/fs/cgroup \
		-v `pwd`:$DOCKERPATH:rw  centos:centos${OS_VERSION} /usr/sbin/init

	DOCKER_CONTAINER_ID=$(docker ps | grep centos | awk '{print $1}')
	docker logs $DOCKER_CONTAINER_ID
	docker exec \
		-ti $DOCKER_CONTAINER_ID \
		/bin/bash -xec "yum -y install epel-release; $BUILDDEPS; pwd; ls -al; perl -c splints/src/perl/fp/v11/splints.pl ; echo -ne \"------\nEND splints TESTS\n\";"
	docker ps -a
	docker stop $DOCKER_CONTAINER_ID
	docker rm -v $DOCKER_CONTAINER_ID

fi

if [ "$DEBUG" -eq "1" ]; then
	date
fi

# EOF
