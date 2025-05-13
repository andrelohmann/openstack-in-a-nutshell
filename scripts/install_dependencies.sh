#!/bin/bash

echo "10.0.0.10 controller controller.os.lokal" >> /etc/hosts
echo "10.0.0.11 compute1 compute1.os.lokal" >> /etc/hosts
echo "10.0.0.12 compute2 compute2.os.lokal" >> /etc/hosts

# Install roles and collections
ansible-galaxy role install -r requirements.yml --force
ansible-galaxy collection install -r requirements.yml --force
