#!/bin/sh




#Terraform deployment

cd /home/master/Somerville
#eval $(ssh-agent)
#sh-add /home/master/.ssh/keys/somerville-openstack
terraform init --upgrade
terraform apply -auto-approve

#terraform apply /home/master/qserv-test/main.tf


#change ansible.cfg


#uncomment line
sudo awk '/#host_key_checking = False/ { sub(/^#/, "", $0) } 1' /etc/ansible/ansible.cfg > /etc/ansible/ansible.cfg.tmp && mv /etc/ansible/ansible.cfg.tmp /etc/ansible/ansible.cfg


cd 
ansible-playbook /home/master/ansible/first.yml

#comment line again
sudo awk '/#host_key_checking = False/ { sub(/^/, "# "); print }' /etc/ansible/ansible.cfg > /etc/ansible/ansible.cfg.tmp && mv /etc/ansible/ansible.cfg.tmp /etc/ansible/ansible.cfg


#ansible deployment

#ansible-playbook -i ansible_hosts









