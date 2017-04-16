#!/usr/bin/env bash
# Armorless-Visage 2017 (c) BSD 3 Clause

# This script is intended to be run on a Fedora 25 hypervisor
# with selinux targeted enforcing

## Configuration ##

vTITLE="testtitle"
vDESCRIPTION="testdesc"

vOS="fedora25"

vCPUS="2"
vCPU_TYPE="host"
vMEM="1536"

# pool must already exist in libvirt
vSTORAGE_POOL="testpool"
# size of volume in GB
vSTORAGE_SIZE="11"

# interface for macvtap
vNET_IF="testif0"

# set vLOCATION to a fedora installation image root
vBOOT_LOCATION="http://download.fedoraproject.org/pub/fedora/linux/releases/25/Server/x86_64/os"
vKS_LOCAL_LOCATION="file:./vm.ks"
vKS_LOCATION="file:/vm.ks"

# leave below alone to get a random 3 byte hex name ie. virt_20170101_9A1AB3
# that is the same as the mac suffix on the primary if ie. 52:54:00:9A:1A:B3
vRAND="$(dd if=/dev/urandom bs=3 count=1 | xxd -u -p)"
vMAC="52:54:00:$(echo $vRAND | head -c 2):$(echo $vRAND | head -c 4 | tail -c 2):$(echo $vRAND | tail -c 3)"
vNAME="virt_$(date +%Y%m%d)_$vRAND"

## 

virt-install --connect qemu:///system \
    --name $vNAME \
    --memory $vMEM \
    --vcpus $vCPUS \
    --cpu $vCPU_TYPE \
    --security type=dynamic,relabel=yes \
    --os-variant $vOS \
    --initrd-inject="$KS_LOCAL_LOCATION" \
    --extra-args="console=hvc0 inst.ks=$KS_LOCATION" \
    --disk size=$vSTORAGE_SIZE,pool=$vSTORAGE_POOL,bus=virtio \
    --network "type=direct,source=$vNET_IF,source_mode=private,model=virtio,mac=$vMAC" \
    --console "target_type=virtio" \
    --rng /dev/urandom \
    --graphics none \
    --location $vBOOT_LOCATION \
    --input keyboard \
    --metadata title="$vTITLE",description="$vDESCRIPTION"

if [[ $? == 0 ]]; then
    echo "Exited OK! Name: $vNAME"
    exit $? 
else
    echo "FAILED! Name: $vNAME"
    exit $? 
fi
