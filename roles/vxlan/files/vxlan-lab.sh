#!/bin/bash
# vxlan-lab.sh up|down|status : VXLAN segments (one bridge per VNI) to the peer laptop over Tailscale
set -euo pipefail
# shellcheck source=/dev/null
. /etc/vxlan-lab.conf                                  # PEER, VNIS, MTU
case "${1:-status}" in
  up)
    for _ in $(seq 60); do ip -4 addr show tailscale0 2>/dev/null | grep -q inet && break; sleep 2; done
    for v in $VNIS; do
      ip link show "br$v"    >/dev/null 2>&1 || ip link add "br$v" type bridge
      ip link show "vxlan$v" >/dev/null 2>&1 || ip link add "vxlan$v" type vxlan id "$v" dstport 4789 remote "$PEER"
      ip link set "vxlan$v" mtu "$MTU" master "br$v" up
      ip link set "br$v" mtu "$MTU" up
    done ;;
  down)
    for v in $VNIS; do ip link del "vxlan$v" 2>/dev/null || true; ip link del "br$v" 2>/dev/null || true; done ;;
  status)
    for v in $VNIS; do ip -d -br link show "vxlan$v" 2>/dev/null || echo "vxlan$v missing"; done
    bridge link | grep -E 'br(10|20)' || true ;;
  *) echo "usage: $0 up|down|status" >&2; exit 2 ;;
esac
