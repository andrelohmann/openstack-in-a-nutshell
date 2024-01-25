# openstack-in-a-nutshell

Documentation and ansible role collection to setup an openstack environment from scratch

## Useful links and

* https://www.youtube.com/watch?v=mCiyTsMvnko
* https://docs.openstack.org/de/install-guide/environment-packages-ubuntu.html

## Keystone

Installing Keystone - the OpenStack Identiy Service

* https://docs.openstack.org/keystone/latest/install/keystone-install-ubuntu.html

### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://localhost:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=3
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
