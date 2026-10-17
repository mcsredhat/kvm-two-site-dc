#!/bin/bash
# vxlan-replug.sh [--dry-run] : re-attach running VMs' tap ports to the bridge named in their definition.
# Needed after a bridge was deleted and recreated (the taps survive, unplugged). Prints one line per fix.
set -euo pipefail
DRY=${1:-}
for d in $(virsh -c qemu:///system list --name); do
  virsh -c qemu:///system domiflist "$d" | awk 'NR>2 && $2=="bridge" {print $1, $3}' |
  while read -r tap br; do
    [ -e "/sys/class/net/$tap" ] && [ -e "/sys/class/net/$br" ] || continue
    cur="" ; [ -L "/sys/class/net/$tap/master" ] && cur=$(basename "$(readlink "/sys/class/net/$tap/master")")
    [ "$cur" = "$br" ] && continue
    if [ "$DRY" = "--dry-run" ]; then echo "would replug $d $tap -> $br"
    else ip link set "$tap" master "$br" up ; echo "replugged $d $tap -> $br"; fi
  done
done
