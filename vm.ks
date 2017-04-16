# Armorless-Visage 2017 (c) BSD 3 Clause

# minimal virtual machine install
# 11 GB of space needed 
# separate /var, /var/log, /var/log/audit, /usr/ with nodev(, noexec, nosuid) 
# default administrator ansibleadm with preinstalled ssh key and seuser staff_u
# default selinux user user_u
# installs new sudoers with NOPASSWD and ROLE sysadm_r for wheel for ansible
# preinstall packages appr. for ansible
# set more restrictive selinux booleans
# BUGS:
#	- silent (probably selinux but no audit logs) problem with modules loading
#  	  for example lsmod shows nfs modules are not loaded until restart with 
#         selinux enforcing=0. Then after one boot if you enforce again it will 
#	  load nfs modules
#	  probably related to known problems with module_load_t selinux
# 	  - fix: don't mess with selinux defaults in ks-post

lang en_US.UTF-8
keyboard us
timezone America/New_York --isUtc --ntpservers='192.168.1.1'
mediacheck

install
url --mirrorlist='https://mirrors.fedoraproject.org/metalink?repo=fedora-25&arch=x86_64'
# configure updates repo
repo --name='updates' --mirrorlist='https://mirrors.fedoraproject.org/metalink?repo=updates-released-f25&arch=x86_64'

# WARNING This will clear all partitions on the device!!!
clearpart
zerombr

bootloader --location='mbr' --append='audit=1 console=hvc0'
part /boot --size='900' --fsoptions='defaults,nodev,noexec,nosuid,x-systemd.device-timeout=0'
part swap --size='1000'
part pv.base --grow --maxsize='20000'
volgroup basevg pv.base
logvol / --vgname='basevg' --size='500' --name='root' --fstype='xfs' --fsoptions='defaults,x-systemd.device-timeout=0'
logvol /var --vgname='basevg' --size='2000' --name='var' --fstype='xfs' --fsoptions='defaults,nodev,x-systemd.device-timeout=0'
logvol /var/log --vgname='basevg' --size='300' --name='log' --fstype='xfs' --fsoptions='defaults,nodev,noexec,nosuid,x-systemd.device-timeout=0' 
logvol /var/log/audit --vgname='basevg' --size='300' --name='audit' --fstype='xfs' --fsoptions='defaults,nodev,noexec,nosuid,x-systemd.device-timeout=0'
logvol /usr --vgname='basevg' --size='4500' --name='usr' --fstype='xfs' --fsoptions='defaults,nodev,x-systemd.device-timeout=0'
logvol /home --vgname='basevg' --grow --size='100' --maxsize='2000' --name='home' --fstype='xfs' --fsoptions='defaults,nodev,nosuid,noexec,x-systemd.device-timeout=0'

firewall --enabled
network --bootproto=dhcp --device=ens2 --onboot=yes --activate
skipx
rootpw --iscrypted '$6$**REMOVED**' 
selinux --enforcing
text
#cmdline

user --name='ansibleadm' --groups='wheel' --iscrypted --password='$6$**REMOVED**'
sshkey --username='ansibleadm' 'ssh-rsa AAAA**REMOVED**'

%packages
@^Minimal Install
@standard
vim
tar
python
ansible
python2-dnf
libselinux
selinux-policy
selinux-policy-sandbox
selinux-policy-targeted
policycoreutils-python
policycoreutils-python-utils
%end

%post --log /root/ks-post.log
#!/bin/bash

# administrative user
postADMUSER="ansibleadm"
# admin selinux roles ( removed unconfined_r and added logadm_r )
postSTAFF_SELINUX_ROLES="staff_r sysadm_r system_r logadm_r"
# default system selinux user
postDEF_SELINUX_USER="user_u"

# set default selinux user
/usr/sbin/semanage login -m -S targeted -s "$postDEF_SELINUX_USER" -r s0 __default__
# root to be unconfined
/usr/sbin/semanage login -a -s unconfined_u root
# staff_u needs extra roles (logadm_r) to function  
/usr/sbin/semanage user -m -R "$postSTAFF_SELINUX_ROLES" staff_u 
# set administrator as selinux user staff_u
/usr/sbin/semanage login -a -s staff_u "$postADMUSER" && \
chcon -R -u staff_u /home/"$postADMUSER"

# allow sudo transition to sysadm_r for wheel
# uses visudo to check file syntax before moving
sed "s/wheel\sALL=(ALL)\sALL/wheel\tALL=(ALL)\tROLE=sysadm_r\tNOPASSWD: ALL/" /etc/sudoers \
> /etc/sudoers.new
chmod 0440 /etc/sudoers.new
visudo -q -c -f /etc/sudoers.new && mv /etc/sudoers.new /etc/sudoers

# uncomment the following to disable unconfined selinux domains
#semodule -d unconfined

# set selinux booleans to tighten up the system
setsebool -P deny_ptrace on
setsebool -P deny_execmem on
setsebool -P selinuxuser_direct_dri_enabled off
setsebool -P selinuxuser_execmod off
setsebool -P selinuxuser_execstack off
setsebool -P selinuxuser_ping off
#setsebool -P unconfined_login off

# restore file contexts
#/usr/sbin/restorecon -R /

# secure_mode restricts modification of selinux 
# if this is creating disposable machines uncomment so no modification
# is allowed.
#setsebool -P secure_mode_insmod on
#setsebool -P secure_mode_policyload on
#setsebool -P secure_mode on

%end

shutdown
