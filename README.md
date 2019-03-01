# Homelab

This is my homelab! It allows me to launch system containers to emulate real nodes in an environment and even bootstrap container based workflows like Kubernetes! I chose LXD because of its ease of install and the ability to use cloud-config which is a big plus in a local environment.

---

## Examples

#### Docker-In-LXD

In this example, I'm launching an ubuntu container on my LAN which installs Docker and exposes the remote api on :2375. From there, I will launch NGINX and be able to see it on my LAN!

```
$ lxc launch -p lan -p docker ubuntu:16.04 docker1 
$ export DOCKER1_IP=$(lxc ls docker1 --format json | jq -r '.[].state.network.eth0.addresses[] | select(.family == "inet").address')
$ export DOCKER_HOST=tcp://$DOCKER1_IP:2375
$ docker run -p 80:80 -d --name nginx nginx:latest
$ curl $DOCKER1_IP
```

---

## Install & Configure LXD

```
$ apt-get install -y lxd lxd-client
$ lxd init
```

Set remote as default
```
$ lxc remote add $URL:8443
$ lxc remote switch $REMOTE_NAME
```

Setup LAN routing so containers can be available on the network

```
$ lxc profile copy default lanprofile
$ lxc profile device set lanprofile eth0 nictype macvlan
$ lxc profile device set lanprofile eth0 parent eno1
$ lxc launch -p lanprofile ubuntu:16.04 net1
$ lxc exec net1 -- apt-get updaate
$ lxc exec net1 -- apt-get install -y nginx
$ curl net1.lan 
```

## Install Profiles

Install default profiles

```
script/install
```

Profiles can be combined to create combinations of nodes

```
lxc launch -p lan -p docker ubuntu:16.04 docker1
```

## Other Helpful Commands

Debug cloud-config startup / check service

```
lxc exec docker1 -- tail -f /var/log/cloud-init-output.log
```

---

## Resources

- https://medium.com/@ali_oguzhan/lxd-assigning-static-ip-to-containers-ecf558982071
- https://dev.to/livioribeiro/using-lxd-and-ansible-to-simulate-infrastructure-2g8l
- https://github.com/Netflix/titus/blob/master/docs/docs/install/cloud-init.yml
- https://linuxacademy.com/containers/training/course/name/lxc-containers-essentials
- https://blog.ubuntu.com/2018/01/26/lxd-5-easy-pieces
