# Level 7 drill report — 18 October 2026

Link: Tailscale direct (IPv6), RTT 55–90 ms; kvm1 on a phone hotspot, kvm2 on home Wi-Fi.
Baseline CPU of web1: IvyBridge-IBRS + features (common to Ice Lake kvm1 and Ivy Bridge kvm2).

## Drill 1 — planned live migration (web1, 768 MiB)
| Run | Direction | Total time (s) | Data (MiB) | Downtime (s) | Site mode |
|---|---|---|---|---|---|
| 1 | kvm2 → kvm1 | 60 | 745 | 0.6 (ping-1.log) | hotspot |
| 2 | kvm1 → kvm2 | 57 | 745 | 0.445 (domjobinfo) | hotspot |

## Drill 2 — node crash failover (ha-web, nested cluster on kvm1)
| Run | Fenced node | RTO: VM running again (s) |
|---|---|---|
| 1 | cl1 | 22 |

## Drill 3 — restore from backup (web1)
| Run | Backup used | Restore + boot time (s) | Marker found |
|---|---|---|---|
| 1 | web1-2026-10-18-1503.qcow2 | 36 | yes |

## Monitoring
HostDown kvm1: pending after 2 min, firing after 7 min (120 s scrape + 5 min for:), cleared after restart.

## Conclusions versus the SLO
- Planned migration: downtime under 0.5 s; total time ~1 min, and it costs ~0.75 GB of mobile data per move.
- Node crash RTO 22 s, after fixing the NFS lease (90 s → 15 s) and the start-failure policy.
- Restore + boot 36 s: well inside a 15 min restore objective.
