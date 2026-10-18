#!/bin/bash
# drain.sh SRC_URI DEST_URI DEST_TAILSCALE_IP : live-migrate every running VM with all disks on the shared pool
#   e.g. ./drain.sh qemu+ssh://kvm2/system qemu:///system "$K1"
set -uo pipefail
SRC=$1 DEST=$2 ADDR=$3 SHARED=/var/lib/libvirt/images/nfs/
for vm in $(virsh -c "$SRC" list --name --state-running); do
  disks=$(virsh -c "$SRC" domblklist "$vm" --details | awk '$2=="disk" {print $4}')
  if echo "$disks" | grep -qv "^$SHARED"; then echo "-- $vm: local disk, NOT movable (shut it down for the maintenance)"; continue; fi
  echo ">> migrating $vm"
  virsh -c "$SRC" migrate --live --persistent --undefinesource --migrateuri "tcp://$ADDR" "$vm" "$DEST" \
    || { echo "FAILED: $vm (it is still running on the source)" >&2; exit 1; }
done
echo "== left on the source:"; virsh -c "$SRC" list --all
