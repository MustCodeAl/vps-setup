# vps-setup
A script to execute common setup tasks on newly created VPS (Virtual Private Servers).

## Description

This script is based on Hetzner Community guides on [How to Keep a VPS Server Safe](https://community.hetzner.com/tutorials/security-ubuntu-settings-firewall-tools) and [Setup Ubuntu Servers](https://community.hetzner.com/tutorials/setup-ubuntu-20-04), it will also install the latest version of docker.

This script is developed for **Debian 12** and **Ubuntu 20.04+**.

### Admin user

In addition to installing and configuring some tools, this script will create an admin user (default: `sysadmin`) for subsequent logins and automated tasks. You can specify a custom username as the second parameter when running the script.

Therefore, in order to execute you will need to copy an `id_ed25519.pub` public key file in the same directory where this script will be run. The execution
will then take care to append that public key to the `/home/<username>/.ssh/authorized_keys` file so you can login using ssh with the newly
created admin user (assuming you have the private key in your machine).

The admin user will have zsh configured as the default shell.

### ssh port

This script will change the default ssh port from 22 to 1222 so in order to log in again you will need to either parametrize the `ssh` command or add a
custom configuration to your `~/.ssh/config` file.
```bash
ssh -p 1222 sysadmin@1.2.3.4
```

```
# ~/.ssh/config
Host 1.2.3.4
  User sysadmin
  IdentityFile ~/.ssh/id_ed25519 # Or whatever your ssh key is.
  Port 1222
```

# How to execute
Copy to the host both the script and the public key for the admin account that will be created then execute the script.

```bash
scp vps-setup.sh root@1.2.3.4:/root/
# If you want a different public key for the admin user replace it
scp ~/.ssh/id_ed25519.pub root@1.2.3.4:/root/

# SSH into the VPS
ssh root@1.2.3.4

# Run the script (from the VPS)
# With default username 'sysadmin':
./vps-setup.sh --confirm

# Or with a custom username:
./vps-setup.sh --confirm myuser
```

Before closing the root session, check that you are able to login with the new admin account:

```bash
# With default username 'sysadmin':
ssh -p 1222 sysadmin@1.2.3.4

# Or with custom username:
ssh -p 1222 myuser@1.2.3.4
```

If you are able to login with the admin account, close the root session. You can validate that root login is disabled by executing:

```bash
ssh root@1.2.3.4
root@1.2.3.4: Permission denied (publickey).
```
