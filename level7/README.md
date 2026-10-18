# Level 7 — HA service across two sites (kvm1 at work, kvm2 at home, Tailscale)

## Service
- `web1`: port 8080 on br10 (VXLAN, MTU 1230), disk on the shared NFS pool, home = kvm2.
  Planned moves (live migration) and backups.
- `ha-web`: VirtualDomain in the nested Pacemaker cluster (cl1, cl2 on kvm1). Unplanned failover.

## SLO
| Objective | Target | Measured (18 Oct 2026) | Met |
|---|---|---|---|
| Planned migration outage | ≤ 5 s | 445 ms downtime (total 57 s) | yes |
| Node-crash RTO (`ha-web`) | ≤ 5 min | 22 s | yes |
| Backup RPO (`web1`) | 24 h | nightly timer 02:15 | yes |
| Restore + boot | ≤ 15 min | 36 s (isolated restore-net) | yes |

## Mobile-data cost accepted
- One planned move of `web1` ≈ its full RAM over Tailscale (measured 745 MiB).
- On the hotspot: at most 1 move per day. Post-copy migration only at home.
- Prometheus scrapes kvm1 every 120 s ≈ 22 MB/day.

## Operations
- Validate: `./validate-level7.sh` (24 checks) and `./test-ha-service.sh`.
- Drills and numbers: `docs/drill-report.md`. Restore drill: `docs/restore-drill.md`.
- `web1` has `autostart` on kvm2.
