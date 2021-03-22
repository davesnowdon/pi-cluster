#! /bin/sh

# ansible
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible

# module for shutdown
ansible-galaxy collection install community.general

# playbook to set up K3S
mkdir -p thirdparty
cd thirdparty
git clone https://github.com/k3s-io/k3s-ansible.git
