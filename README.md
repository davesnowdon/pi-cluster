# pi-cluster
Scripts and code to configure of cluster of Raspberry Pis running kubernetes

## Create SSH key

Creates new SSH key in `$HOME/.ssh/picluster_rsa`

```
./scripts/make-ssh.sh
```

## Create and configure SD card

Download the RaspiOS distribution if not already downloaded, write it to an SD card on the specified device and configure the card to boot with SSH enabled, hostname set and SSH key confgured for `pi` user.

For example:

```
./scripts/make-sdcard.sh /dev/sdg picluster1 ~/.ssh/picluster_rsa.pub
```

## Check connectivity (and inventory)

```
ansible nodes -m ping -u pi -i inventory/hosts.yml
```

## Update OS

```
ansible-playbook -i inventory/hosts.yml update.yml
```

## Installing kubernetes
Use: https://github.com/k3s-io/k3s-ansible