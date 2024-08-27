# openstack-in-a-nutshell

Documentation and ansible role collection to setup an openstack environment from scratch.

Just clone the repo and run

```
vagrant up
```

## Useful links and

* https://www.youtube.com/watch?v=wsy9OY-ot7E
* https://www.youtube.com/watch?v=mCiyTsMvnko
* https://docs.openstack.org/install-guide/index.html
* https://docs.openstack.org/install-guide/openstack-services.html
* https://docs.openstack.org/de/install-guide/environment-packages-ubuntu.html
* https://docs.openstack.org/python-openstackclient/latest/
* https://www.openstack.org/use-cases/enterprise/
* https://docs.openstack.org/python-openstackclient/2024.1/´

## Network

* https://docs.openstack.org/install-guide/environment-networking.html
* https://docs.openstack.org/install-guide/environment-ntp.html

## Nodes

* https://docs.openstack.org/install-guide/openstack-services.html

### Controller

#### Dependencies

!!! Currently the network is not taken into concideration. Therefor the Etcd config and nova my_ip config got passed the default vagrant nated IP of 10.0.2.15.

#### Keystone

Installing Keystone - the OpenStack Identity Service

* https://docs.openstack.org/keystone/2024.1/install/index-ubuntu.html

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Create project for services

```
openstack project create --domain default --description "Service Project" service
```

Create demo project

```
openstack project create --domain default --description "Demo Project" demo
```

Create a user "demo" for the demo project

```
openstack user create --domain default --password-prompt demo
```

Create the "user" role

```
openstack role create user
```

Put all together

```
openstack role add --project demo --user demo user
```

#### glance

Install glance - the OpenStack Image Service

* https://docs.openstack.org/glance/latest/install/install-ubuntu.html

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Download the cirros image

```
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
```

Upload the cirros image

```
openstack image create --file ./cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public cirros
```

Verify the image was uploaded

```
openstack image list
```

###### Todo

Following commands are failing currently:

```
glance image-create --name "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility=public
glance image-list
```

#### placement

Install placement - the OpenStack placement service used to track resource provider inventories and usages

* https://docs.openstack.org/placement/2024.1/install/install-ubuntu.html

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Perform status checks - user needs to be in group placement

```
placement-status upgrade check
```

List available resources and traits

```
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
```

#### nova

Install nova - the OpenStack compute service

* https://docs.openstack.org/nova/2024.1/install/controller-install-ubuntu.html

##### Test

Verify nova cell0 and cell1 are registered correctly

```
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
```
