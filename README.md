# Homelab

This is my homelab! It allows me to launch system containers to emulate real nodes in an environment and even bootstrap container based workflows like Kubernetes! I chose LXD because of its ease of install and the ability to use cloud-config which is a big plus in a local environment.

## Bare Metal Setup

This will setup a python environment and install ansible using anaconda

```
conda config --add channels conda-forge
conda env create -f conda.yaml
conda activate ansible
```

Install tools locally that will be needed

```
brew bundle
```

From the server, run these commands

```
$ apt -y update && apt install -y python-minimal zfsutils-linux
$ snap install lxd
$ cat <<EOF | lxd init --preseed
config:
  core.https_address: '[::]:8443'
  core.trust_password: "octolab"
networks:
- config:
    ipv4.address: auto
    ipv6.address: none
  description: ""
  managed: false
  name: lxdbr0
  type: ""
storage_pools: []
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
  name: default
cluster: null
EOF
$ sudo visudo
```

Change the sudo line to have `NOPASSWD`

```
%sudo   ALL=(ALL:ALL) ALL
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
```

```
$ lxc remote add $URL:8443
$ lxc remote switch $REMOTE_NAME
```

Containers can be created with Ansible and then managed with them:

```
ansible-playbook -i inventory/hashistack plays/hashistack.yml
```

This will build a full consul/nomad stack! UI will be available at `http://nomad-server1.lan:4646`, `http://consul1.lan:8500` and `http://proxy.lan:8080`

To teardown you can then run:

```
ansible-playbook -i hashistack destroy.yml
```

---

## Examples

#### Nomad Scheduling

```
export NOMAD_ADDR="http://nomad-server1.lan:4646"
nomad node status
```

#### Ansible + LXD

The container to be managed by Ansible must have python and use the `base` role, here is an example of how to launch one:

```
lxc launch -p lan -p base ubuntu:16.04 my-container
```

After launching a container through LXD (or Ansible) it needs to be entered into an inventory using this format:

```
[group]
$name  ansible_connection=lxd ansible_host=$remote:$name
```

If you launch a container named `my-container` on your remote host `lab` the entry would look like this:

```
[all]
my-container  ansible_connection=lxd ansible_host=lab:my-container
```

Then you can run to test

```
ansible all -i inventory -m ping -vvvv

my-container | SUCCESS => {
    "changed": false,
    "invocation": {
        "module_args": {
            "data": "pong"
        }
    },
    "ping": "pong"
}
```

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

## Resources

- https://medium.com/@ali_oguzhan/lxd-assigning-static-ip-to-containers-ecf558982071
- https://dev.to/livioribeiro/using-lxd-and-ansible-to-simulate-infrastructure-2g8l
- https://github.com/Netflix/titus/blob/master/docs/docs/install/cloud-init.yml
- https://linuxacademy.com/containers/training/course/name/lxc-containers-essentials
- https://blog.ubuntu.com/2018/01/26/lxd-5-easy-pieces
- https://blog.ubuntu.com/2018/05/03/lxd-clusters-a-primer
- https://discuss.linuxcontainers.org/t/lxd-clustering-single-node-cluster-or-convert-standalone-to-cluster/2982/2

