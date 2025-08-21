# Ceph OSD Role

This role configures Ceph Object Storage Daemons (OSDs) in an idempotent manner.

## Purpose

The `ceph_osd` role is responsible for:

1. **Installing OSD packages**: Installs `ceph-osd` and `gdisk` packages
2. **Configuring OSD settings**: Updates `ceph.conf` with OSD-specific configuration
3. **Setting up bootstrap keyring**: Creates and distributes the bootstrap-osd authentication keyring
4. **Creating OSDs**: Prepares and creates OSDs on specified block devices using `ceph-volume`
5. **Verification**: Ensures OSDs are running and properly integrated into the cluster

## Key Features

- **Idempotent Design:**
  - Checks for existing OSDs before creating new ones
  - Only creates OSDs on devices that don't already have them (unless `ceph_osd_force_zap` is true)
  - Only updates configuration when changes are needed
  - Handles bootstrap keyring creation and distribution safely
  - Safe to run multiple times without causing issues

## Variables

### Default Variables (in `defaults/main.yml`)

- `ceph_osd_devices`: List of block devices to use for OSDs (default: `/dev/sdb`, `/dev/sdc`)
- `ceph_osd_memory_target_autotune`: Whether to enable automatic memory tuning (default: `false`)
- `ceph_osd_memory_target`: Memory target in bytes for test environments (default: `1073741824` = 1 GiB)
- `ceph_osd_force_zap`: Whether to force zap existing data on devices (default: `false`)
  - When `false`: Skips devices that already have OSDs (idempotent behavior)
  - When `true`: Destroys existing OSDs and recreates them (useful for testing/reset)
- `ceph_bootstrap_osd_keyring_path`: Path to bootstrap OSD keyring (default: `/var/lib/ceph/bootstrap-osd/ceph.keyring`)
- `ceph_osd_service_start_wait`: Wait time for OSD services to start (default: `30` seconds)

### Host-specific Variables

You can customize OSD devices per host in `host_vars/hostname/main.yml`:

```yaml
ceph_osd_devices:
  - /dev/sdb
  - /dev/sdc
  - /dev/sdd  # Additional device
```

## Usage

Include this role in your playbook after the `ceph_mon` and `ceph_mgr` roles:

```yaml
- name: Install Ceph OSDs
  hosts: ceph_osds
  gather_facts: true
  become: true
  become_method: ansible.builtin.sudo
  
  roles:
    - ceph_common
    - ceph_mon
    - ceph_mgr
    - ceph_osd
```

## Prerequisites

1. **Ceph monitors and managers must be running**: This role assumes that `ceph_mon` and `ceph_mgr` roles have been applied
2. **Block devices available**: The specified devices in `ceph_osd_devices` must exist on the target hosts
3. **Network connectivity**: OSD nodes must be able to communicate with monitor nodes
4. **Proper inventory**: Hosts should be in the `ceph_osds` group in the Ansible inventory

## Tasks Overview

1. **Configure OSD settings**: Updates `/etc/ceph/ceph.conf` with memory and performance settings
2. **Install packages**: Installs required Ceph OSD packages
3. **Prepare bootstrap keyring**: (First host only) Creates bootstrap-osd authentication key
4. **Setup keyring**: Distributes bootstrap keyring to all OSD nodes
5. **Create OSDs**: Uses `ceph-volume lvm` to create OSDs on specified devices
6. **Verify OSDs**: Checks that OSDs are running and joined to the cluster

## Idempotency

The role is designed to be idempotent:

- Configuration changes only occur when settings differ
- OSDs are only created on devices that don't already have them (unless `ceph_osd_force_zap` is true)
- Services are only restarted when configuration changes
- Bootstrap keyring is only created once and reused

## Safety Features

**Important**: By default, `ceph_osd_force_zap` is set to `false` to prevent accidental data loss:

- **Normal operation**: The role will skip devices that already have OSDs
- **Force recreation**: Set `ceph_osd_force_zap: true` to destroy and recreate existing OSDs
- **Proper cleanup**: When force zapping, the role properly stops OSD services and removes them from the cluster before destroying the data

⚠️ **Warning**: Setting `ceph_osd_force_zap: true` will **destroy all data** on the specified devices and recreate the OSDs. Only use this for testing or when you intentionally want to reset the storage.

## Security

- Bootstrap keyring is created with proper Ceph user ownership and restrictive permissions
- Temporary files are cleaned up after use
- Authentication follows Ceph best practices

## Error Handling

- Validates that specified devices exist before attempting to create OSDs
- Handles cases where devices may already have OSDs
- Provides clear error messages for common failure scenarios
- Gracefully handles missing OSD services during restart operations

## Testing

After running this role, verify:

1. All OSDs are visible in `ceph osd tree`
2. OSDs are in `up` and `in` state
3. Cluster health shows OSDs are functioning
4. Local OSD services are active: `systemctl status ceph-osd@*`
