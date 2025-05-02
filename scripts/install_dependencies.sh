#!/bin/bash

# Download and add certificate
sudo wget --no-check-certificate https://ca.cc.lan/root_ca.der -O /root/root-ca.der
sudo openssl x509 -inform der -outform pem -in /root/root-ca.der -out /root/root-ca.crt
sudo mkdir /usr/local/share/ca-certificates/cloudcourse
sudo mv /root/root-ca.crt /usr/local/share/ca-certificates/cloudcourse/
sudo chown root:root /usr/local/share/ca-certificates/cloudcourse/root-ca.crt 
sudo chmod 644 /usr/local/share/ca-certificates/cloudcourse/root-ca.crt 
sudo update-ca-certificates && sudo update-ca-certificates -f

# Install python requirements
#sudo pip3 install -r requirements.txt --break-system-packages --root-user-action=ignore
# --break-system-packages <- is a dirty workaorund!! better use pipx and/or venv in the future
# xargs -a requirements.txt -I {} pipx install {}
# Define a default venv for pipx installations
# Load the default venv (?)

# Install roles and collections
ansible-galaxy role install -r requirements.yml --force
ansible-galaxy collection install -r requirements.yml --force
